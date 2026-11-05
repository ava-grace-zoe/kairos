import fs from 'node:fs';
import { createRequire } from 'node:module';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
// 仅由完整验收脚本传入其新建的隔离工程，数据库生命周期由调用方管理。
const root = process.argv[2];
if (!root) throw new Error('需要隔离验收工程的绝对路径。');
process.chdir(root);
const { start, stop } = await import(pathToFileURL(`${root}/scripts/processes.mjs`));
const require = createRequire(`${root}/package.json`);
const pg = require('pg');
const { config } = require('dotenv');
config({ quiet: true });
fs.mkdirSync('test-results', { recursive: true });
const logFile = 'test-results/runtime-audit.log';
let interrupted = false;
process.once('SIGINT', () => { interrupted = true; if (dev) void stop([dev]); });
process.once('SIGTERM', () => { interrupted = true; if (dev) void stop([dev]); });
function run(command, args, expected = 0) {
  const result = spawnSync(command, args, { stdio: 'pipe', encoding: 'utf8', timeout: 120000 });
  fs.appendFileSync(logFile, result.stdout + result.stderr);
  assert.equal(result.status, expected, `${command} ${args.join(' ')}\n${result.stdout}\n${result.stderr}`);
  return result;
}
async function waitFor(predicate, label, milliseconds = 45000) {
  const until = Date.now() + milliseconds;
  while (Date.now() < until) {
    if (interrupted) throw new Error('验收已取消');
    if (dev && (dev.child.exitCode !== null || dev.child.signalCode !== null)) throw new Error(`开发进程提前退出：${dev.output()}`);
    try { if (await predicate()) return; } catch {}
    await new Promise(resolve => setTimeout(resolve, 300));
  }
  throw new Error(`超时：${label}`);
}
const health = async (port) => (await fetch(`http://127.0.0.1:${port}/api/health`, {signal: AbortSignal.timeout(1000)})).json();
let dev;
let database;
const ownedFiles = [];
const injected = 'apps/web/src/forbidden-audit.ts';
const failureTest = 'tests/system/injected-failure.test.ts';
const sharedFile = 'packages/utilities/src/index.ts';
const sharedSource = fs.readFileSync(sharedFile, 'utf8');
const apiFile = 'apps/api/src/app.module.ts';
const apiSource = fs.readFileSync(apiFile, 'utf8');
try {
  assert.equal(fs.existsSync(injected), false, '拒绝覆盖已有文件');
  assert.equal(fs.existsSync(failureTest), false, '拒绝覆盖已有测试');
  for (const port of [3000,3001,5173,5174]) {
    let occupied = false;
    try { await fetch(`http://127.0.0.1:${port}`, {signal: AbortSignal.timeout(500)}); occupied = true; } catch {}
    assert.equal(occupied, false, `验收端口 ${port} 已被占用，请先改用空闲环境`);
  }
  ownedFiles.push(injected);
  fs.writeFileSync(injected, "import 'node:fs';\n");
  const rejected = run('pnpm', ['check:boundaries'], 1);
  assert.match(rejected.stderr + rejected.stdout, /导入服务端模块/);
  fs.unlinkSync(injected);
  run('pnpm', ['check:boundaries']);
  console.log('非法前端导入被拒绝，移除后边界检查通过。');
  dev = start('pnpm', ['dev'], { env: { ...process.env, FORGE_WATCH_POLLING: '1' } });
  await waitFor(async () => (await health(3000)).status === 'ok' && (await health(3001)).status === 'ok', '两个后端启动');
  for (const port of [5173,5174]) await waitFor(async () => (await fetch(`http://127.0.0.1:${port}`)).ok, `前端 ${port}`);
  fs.writeFileSync(apiFile, apiSource.replace("service: 'api'", "service: 'api-reloaded'"));
  await waitFor(async () => (await health(3000)).service === 'api-reloaded', '后端热更新');
  fs.writeFileSync(apiFile, apiSource);
  await waitFor(async () => (await health(3000)).service === 'api', '后端恢复');
  const dist = 'packages/utilities/dist/index.js';
  fs.writeFileSync(sharedFile, sharedSource + '\nexport const watchAudit = "watch-ready";\n');
  await waitFor(() => fs.readFileSync(dist, 'utf8').includes('watch-ready'), '共享包监听重编译');
  fs.writeFileSync(sharedFile, sharedSource);
  await waitFor(() => !fs.readFileSync(dist, 'utf8').includes('watch-ready'), '共享包恢复');
  await stop([dev]);
  fs.appendFileSync(logFile, dev.output());
  dev = undefined;
  for (const port of [3000,3001,5173,5174]) await waitFor(async () => {
    try { await fetch(`http://127.0.0.1:${port}`, {signal: AbortSignal.timeout(500)}); return false; } catch { return true; }
  }, `端口 ${port} 释放`, 10000);
  console.log('开发模式四个应用可访问，后端热更新与共享包监听生效，停止后四个端口释放。');
  const url = new URL(process.env.DATABASE_URL);
  url.searchParams.delete('schema');
  database = new pg.Client({ connectionString: url.toString() });
  await database.connect();
  const schemas = async () => (await database.query("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'forge_test_%' ORDER BY schema_name")).rows;
  const before = await schemas();
  const connections = async () => Number((await database.query("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()")).rows[0].count);
  const connectionCount = await connections();
  ownedFiles.push(failureTest);
  fs.writeFileSync(failureTest, "import { it } from 'vitest';\nit('故意失败以验证清理', () => { throw new Error('FORGE_EXPECTED_FAILURE'); });\n");
  const failed = run(process.execPath, ['scripts/system-test.mjs'], 1);
  assert.match(failed.stderr + failed.stdout, /FORGE_EXPECTED_FAILURE/);
  assert.match(failed.stdout, /系统测试资源已清理/);
  assert.deepEqual(await schemas(), before);
  await waitFor(async () => await connections() === connectionCount, '测试服务数据库连接关闭', 10000);
  console.log('故意触发系统测试失败，退出码为 1，隔离数据库模式已清理。');
} finally {
  fs.writeFileSync(sharedFile, sharedSource);
  fs.writeFileSync(apiFile, apiSource);
  for (const file of ownedFiles) fs.rmSync(file, { force:true });
  if (dev) { await stop([dev]); fs.appendFileSync(logFile, dev.output()); }
  if (database) await database.end();

}
