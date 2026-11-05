import { defineProject } from 'vitest/config';

export default defineProject({
  test: {
    name: '__PROJECT_NAME__',
    root: import.meta.dirname,
    include: ['src/**/*.test.ts'],
    exclude: ['src/**/*.browser.test.tsx'],
  },
});
