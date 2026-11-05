{
  "name": "@__SCOPE__/database",
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
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate deploy",
    "db:dev": "prisma migrate dev",
    "db:studio": "prisma studio",
    "build": "tsc -p tsconfig.build.json",
    "dev": "tsc -p tsconfig.build.json --watch",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  },
  "dependencies": {
    "@prisma/client": "catalog:",
    "@prisma/adapter-pg": "catalog:",
    "pg": "catalog:"
  },
  "devDependencies": {
    "prisma": "catalog:",
    "typescript": "catalog:",
    "@types/node": "catalog:",
    "@types/pg": "catalog:",
    "dotenv": "catalog:",
    "vitest": "catalog:"
  }
}
