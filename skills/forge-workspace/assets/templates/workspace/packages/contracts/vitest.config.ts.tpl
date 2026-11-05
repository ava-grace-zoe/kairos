import { defineProject } from 'vitest/config';

export default defineProject({
  test: { name: 'contracts', root: import.meta.dirname, include: ['src/**/*.test.ts'] },
});
