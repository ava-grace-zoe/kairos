{
  "name": "@__SCOPE__/__PROJECT_NAME__",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "swc src --out-dir dist --strip-leading-paths --ignore \"**/*.test.ts\"",
    "dev": "node ../../scripts/watch-api.mjs",
    "start": "node --env-file-if-exists=../../.env dist/main.js",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  },
  "dependencies": {
    "@__SCOPE__/contracts": "workspace:*",
    "@__SCOPE__/database": "workspace:*",
    "@nestjs/common": "catalog:",
    "@nestjs/core": "catalog:",
    "@nestjs/platform-express": "catalog:",
    "reflect-metadata": "catalog:",
    "rxjs": "catalog:",
    "zod": "catalog:"
  },
  "devDependencies": {
    "typescript": "catalog:",
    "@types/node": "catalog:",
    "@nestjs/testing": "catalog:",
    "@swc/core": "catalog:",
    "@swc/cli": "catalog:",
    "chokidar": "catalog:",
    "unplugin-swc": "catalog:",
    "vitest": "catalog:"
  }
}
