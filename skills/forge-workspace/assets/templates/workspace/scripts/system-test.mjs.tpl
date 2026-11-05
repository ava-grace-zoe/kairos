import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import net from 'node:net';
import { config } from 'dotenv';
import pg from 'pg';
import { start, stop } from './processes.mjs';

config({ path: '.env', quiet: true });
if (process.env.FORGE_TEST_DATABASE_URL)
  process.env.DATABASE_URL = process.env.FORGE_TEST_DATABASE_URL;
if (!process.env.DATABASE_URL)
  throw new Error('缺少 DATABASE_URL，请先从 .env.example 创建 .env 并启动数据库。');
const connection = new URL(process.env.DATABASE_URL);
if (
  !process.env.FORGE_TEST_DATABASE_URL &&
  !['127.0.0.1', 'localhost', '[::1]'].includes(connection.hostname)
)
  throw new Error('远端系统测试必须显式提供独立测试库 FORGE_TEST_DATABASE_URL。');
connection.searchParams.delete('schema');
const database = new pg.Client({ connectionString: connection.toString() });
const schema = `forge_test_${randomUUID().replaceAll('-', '')}`;
const processes = [];
let created = false;
let connected = false;
let interrupted = false;

async function availablePort() {
  const server = net.createServer();
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const address = server.address();
  const port = address.port;
  await new Promise((resolve) => server.close(resolve));
  return port;
}

async function ready(url, child) {
  const deadline = Date.now() + 30000;
  while (Date.now() < deadline) {
    if (interrupted) throw new Error('系统测试已取消');
    if (child.child.exitCode !== null || child.child.signalCode !== null)
      throw new Error(`服务提前退出：${child.output()}`);
    try {
      if ((await fetch(url, { signal: AbortSignal.timeout(1000) })).ok) return;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error(`服务未就绪：${url}\n${child.output()}`);
}

const shutdown = () => {
  interrupted = true;
  void stop(processes);
};
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);

try {
  await database.connect();
  connected = true;
  await database.query(`CREATE SCHEMA "${schema}"`);
  created = true;
  connection.searchParams.set('schema', schema);
  const environment = { ...process.env, DATABASE_URL: connection.toString() };
  const migration = spawnSync('pnpm', ['--filter', '@__SCOPE__/database', 'db:migrate'], {
    env: environment,
    stdio: 'inherit',
  });
  if (migration.status !== 0) throw new Error('测试数据库迁移失败。');
  if (interrupted) throw new Error('系统测试已取消');
  const apiPort = await availablePort();
  const webPort = await availablePort();
  const apiUrl = `http://127.0.0.1:${apiPort}`;
  const webUrl = `http://127.0.0.1:${webPort}`;
  const api = start(process.execPath, ['apps/api/dist/main.js'], {
    env: { ...environment, PORT: String(apiPort) },
  });
  processes.push(api);
  await ready(`${apiUrl}/api/health`, api);
  const web = start(
    'pnpm',
    [
      '--filter',
      '@__SCOPE__/web',
      'exec',
      'vite',
      'preview',
      '--host',
      '127.0.0.1',
      '--port',
      String(webPort),
    ],
    { env: { ...environment, VITE_API_TARGET: apiUrl } },
  );
  processes.push(web);
  await ready(webUrl, web);
  const tests = start('pnpm', ['exec', 'vitest', 'run', '--config', 'vitest.system.config.ts'], {
    env: { ...environment, TEST_API_URL: apiUrl, TEST_WEB_URL: webUrl },
    stdio: 'inherit',
  });
  processes.push(tests);
  process.exitCode = await tests.done;
  if (process.exitCode) console.error(api.output(), web.output());
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  try {
    await stop(processes);
  } finally {
    try {
      if (created) await database.query(`DROP SCHEMA "${schema}" CASCADE`);
    } finally {
      if (connected) await database.end();
    }
  }
  console.log('系统测试资源已清理：服务进程和本次隔离数据库模式。');
}
