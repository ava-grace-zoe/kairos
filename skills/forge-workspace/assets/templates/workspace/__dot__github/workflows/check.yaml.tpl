name: 工程检查
on:
  push:
  pull_request:
jobs:
  check:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:18.3-alpine
        env:
          POSTGRES_USER: forge
          POSTGRES_PASSWORD: forge_local
          POSTGRES_DB: __WORKSPACE__
        ports:
          - 54329:5432
        options: >-
          --health-cmd "pg_isready -U forge -d __WORKSPACE__"
          --health-interval 5s --health-timeout 5s --health-retries 10
    env:
      DATABASE_URL: postgresql://forge:forge_local@127.0.0.1:54329/__WORKSPACE__?schema=public
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 10.28.0
      - uses: actions/setup-node@v4
        with:
          node-version-file: .node-version
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps chromium
      - run: pnpm check
      - run: pnpm db:migrate
      - run: pnpm test:browser
      - run: pnpm test:system
