{
  "name": "__WORKSPACE__",
  "private": true,
  "type": "module",
  "packageManager": "pnpm@10.28.0",
  "engines": {
    "node": ">=22.23.2 <23 || >=24.11.0 <25 || >=26.0.0 <27"
  },
  "scripts": {
    "dev": "pnpm db:generate && pnpm build && node scripts/dev.mjs",
    "build:packages": "pnpm -r --filter './packages/**' run build",
    "build": "pnpm -r run build",
    "typecheck": "pnpm -r run typecheck && tsc --noEmit -p tsconfig.tests.json",
    "lint": "biome check .",
    "format": "biome check --write .",
    "test": "vitest run --config vitest.config.ts",
    "test:coverage": "vitest run --coverage --config vitest.config.ts",
    "test:browser": "vitest run --config vitest.browser.config.ts",
    "test:system": "pnpm build && node scripts/system-test.mjs",
    "check": "pnpm db:generate && pnpm lint && pnpm check:boundaries && pnpm build && pnpm typecheck && pnpm test",
    "db:up": "docker compose up -d --wait postgres",
    "db:down": "docker compose down",
    "db:generate": "pnpm --filter @__SCOPE__/database db:generate",
    "db:migrate": "pnpm --filter @__SCOPE__/database db:migrate",
    "db:dev": "pnpm --filter @__SCOPE__/database db:dev",
    "db:studio": "pnpm --filter @__SCOPE__/database db:studio",
    "check:boundaries": "node scripts/check-boundaries.mjs"
  },
  "devDependencies": {
    "typescript": "catalog:",
    "@biomejs/biome": "catalog:",
    "@types/node": "catalog:",
    "@types/pg": "catalog:",
    "vitest": "catalog:",
    "@vitest/coverage-v8": "catalog:",
    "playwright": "catalog:",
    "pg": "catalog:",
    "dotenv": "catalog:"
  }
}
