import { defineProject } from 'vitest/config';

export default defineProject({
  test: { name: 'database', root: import.meta.dirname, include: ['src/**/*.test.ts'] },
});
