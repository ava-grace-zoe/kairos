import { defineConfig } from 'tsdown';

export default defineConfig({
  entry: ['src/index.ts'],
  inputOptions: {
    watch: { watcher: { usePolling: process.env.FORGE_WATCH_POLLING === '1', pollInterval: 300 } },
  },
  format: 'esm',
  platform: 'neutral',
  dts: true,
  sourcemap: true,
  clean: true,
  deps: { neverBundle: true },
});
