import fs from 'node:fs';
import path from 'node:path';
import { start, stop } from './processes.mjs';

const root = path.resolve('../..');
const metadata = JSON.parse(fs.readFileSync(path.join(root, '.forge/workspace.json'), 'utf8'));
const directories = [
  path.resolve('dist'),
  ...metadata.projects
    .filter((project) => project.path.startsWith('packages/'))
    .map((project) => path.join(root, project.path, 'dist')),
];
const watchers = [];
let compiler;
let server;
let timer;
let polling;
let closing = false;
let restarting = Promise.resolve();
let finish;
const finished = new Promise((resolve) => {
  finish = resolve;
});

function scheduleRestart() {
  if (closing) return;
  clearTimeout(timer);
  timer = setTimeout(() => {
    restarting = restarting.then(async () => {
      if (server) await stop([server]);
      if (!closing)
        server = start(process.execPath, ['--env-file-if-exists=../../.env', 'dist/main.js'], {
          stdio: 'inherit',
          detached: false,
        });
    });
    restarting.catch((error) => {
      console.error(error);
      finish(1);
    });
  }, 150);
}

process.once('SIGINT', () => finish(0));
process.once('SIGTERM', () => finish(0));
try {
  // 只监听本工程构建产物，避免递归跟踪整个第三方依赖树。
  if (process.env.FORGE_WATCH_POLLING === '1') {
    const snapshot = () =>
      JSON.stringify(
        directories.flatMap((directory) =>
          fs
            .readdirSync(directory, { recursive: true })
            .filter((file) => /\.(?:js|json)$/.test(file))
            .sort()
            .map((file) => {
              const stat = fs.statSync(path.join(directory, file));
              return [directory, file, stat.mtimeMs, stat.size];
            }),
        ),
      );
    let previous = snapshot();
    polling = setInterval(() => {
      try {
        const current = snapshot();
        if (current !== previous) {
          previous = current;
          scheduleRestart();
        }
      } catch (error) {
        console.error(error);
        finish(1);
      }
    }, 300);
  } else
    for (const directory of directories) {
      const watcher = fs.watch(directory, { recursive: true }, (_event, filename) => {
        if (!filename || /\.(?:js|json)$/.test(String(filename))) scheduleRestart();
      });
      watcher.on('error', (error) => {
        console.error(error);
        finish(1);
      });
      watchers.push(watcher);
    }
  compiler = start(
    'pnpm',
    [
      'exec',
      'swc',
      'src',
      '--out-dir',
      'dist',
      '--strip-leading-paths',
      '--ignore',
      '**/*.test.ts',
      '--watch',
    ],
    { stdio: 'inherit', detached: false },
  );
  scheduleRestart();
  process.exitCode = await Promise.race([finished, compiler.done]);
} finally {
  closing = true;
  clearTimeout(timer);
  clearInterval(polling);
  for (const watcher of watchers) watcher.close();
  await restarting;
  await stop([compiler, server].filter(Boolean));
}
