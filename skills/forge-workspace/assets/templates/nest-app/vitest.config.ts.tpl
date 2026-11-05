import swc from 'unplugin-swc';
import { defineProject } from 'vitest/config';

export default defineProject({
  plugins: [
    swc.vite({
      swcrc: false,
      jsc: {
        parser: { syntax: 'typescript', decorators: true },
        transform: { legacyDecorator: true, decoratorMetadata: true },
        target: 'es2022',
      },
      module: { type: 'es6' },
    }),
  ],
  test: {
    name: '__PROJECT_NAME__',
    root: import.meta.dirname,
    include: ['src/**/*.test.ts'],
    environment: 'node',
  },
});
