import react from '@vitejs/plugin-react';
import { playwright } from '@vitest/browser-playwright';
import { defineProject } from 'vitest/config';

export default defineProject({
  plugins: [react()],
  test: {
    name: '__PROJECT_NAME__-browser',
    root: import.meta.dirname,
    include: ['src/**/*.browser.test.tsx'],
    browser: {
      enabled: true,
      headless: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
    },
  },
});
