{
  "private": true,
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "files": [
    "dist"
  ],
  "scripts": {
    "build": "tsdown",
    "dev": "tsdown --watch --no-clean",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  },
  "name": "@__SCOPE__/contracts",
  "dependencies": {
    "zod": "catalog:"
  },
  "devDependencies": {
    "typescript": "catalog:",
    "tsdown": "catalog:",
    "vitest": "catalog:"
  }
}
