{
  "name": "@__SCOPE__/__PROJECT_NAME__",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite --host 127.0.0.1",
    "build": "vite build",
    "preview": "vite preview --host 127.0.0.1",
    "typecheck": "tsc --noEmit",
    "test": "vitest run --config vitest.config.ts",
    "test:browser": "vitest run --config vitest.browser.config.ts"
  },
  "dependencies": {
    "@__SCOPE__/contracts": "workspace:*",
    "react": "catalog:",
    "react-dom": "catalog:",
    "react-router": "catalog:",
    "zustand": "catalog:"
  },
  "devDependencies": {
    "typescript": "catalog:",
    "@types/react": "catalog:",
    "@types/react-dom": "catalog:",
    "@types/node": "catalog:",
    "vite": "catalog:",
    "@vitejs/plugin-react": "catalog:",
    "tailwindcss": "catalog:",
    "@tailwindcss/vite": "catalog:",
    "vitest": "catalog:",
    "@vitest/browser-playwright": "catalog:",
    "vitest-browser-react": "catalog:",
    "playwright": "catalog:"
  }
}
