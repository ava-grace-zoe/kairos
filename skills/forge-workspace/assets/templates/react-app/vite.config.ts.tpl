import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
  const environment = loadEnv(mode, '../..', '');
  return {
    plugins: [react(), tailwindcss()],
    server: {
      port: __PORT__,
      strictPort: true,
      proxy: {
        '/api':
          process.env.VITE_API_TARGET ?? environment.VITE_API_TARGET ?? 'http://127.0.0.1:__API_PORT__',
      },
    },
    preview: { port: __PORT__, strictPort: true },
  };
});
