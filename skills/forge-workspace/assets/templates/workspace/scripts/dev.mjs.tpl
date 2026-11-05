import { watchGroup } from './processes.mjs';

// 文件系统不支持原生监听时，显式开启兼容模式。
if (process.env.FORGE_WATCH_POLLING === '1') {
  console.log('开发监听使用轮询模式；可通过 FORGE_WATCH_POLLING=1 显式启用。');
  process.env.FORGE_WATCH_POLLING = '1';
  process.env.CHOKIDAR_USEPOLLING = 'true';
  process.env.CHOKIDAR_INTERVAL = '300';
  process.env.TSC_WATCHFILE = 'DynamicPriorityPolling';
  process.env.TSC_WATCHDIRECTORY = 'RecursiveDirectoryUsingDynamicPriorityPolling';
}
await watchGroup([
  ['pnpm', ['-r', '--parallel', '--filter', './packages/**', 'run', 'dev']],
  ['pnpm', ['-r', '--parallel', '--filter', './apps/**', 'run', 'dev']],
]);
