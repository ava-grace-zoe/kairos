#!/usr/bin/env bash
set -euo pipefail

# 每次使用独立工作区、缓存、数据库端口和容器项目；不读写其他项目的数据。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
keep=false
if [[ "${1:-}" == '--keep' ]]; then
  keep=true
elif [[ $# -gt 0 ]]; then
  echo '用法：bash scripts/smoke-forge-workspace.sh [--keep]；需要匹配的 Node.js、pnpm 和 Docker。' >&2
  exit 1
fi
command -v node >/dev/null
command -v pnpm >/dev/null
docker info >/dev/null

smoke_root="$(mktemp -d "${TMPDIR:-/tmp}/forge-smoke.XXXXXX")"
smoke_workspace="$smoke_root/workspace"
export FORGE_CACHE_DIR="$smoke_root/cache"
export COMPOSE_PROJECT_NAME="forge-smoke-$$-$RANDOM"
export PLAYWRIGHT_SKIP_BROWSER_GC=1

cleanup() {
  smoke_status=$?
  if [[ -f "$smoke_workspace/compose.yaml" ]]; then
    docker compose --project-directory "$smoke_workspace" -p "$COMPOSE_PROJECT_NAME" down --volumes >/dev/null 2>&1 || true
  fi
  if [[ "$keep" == true || $smoke_status -ne 0 ]]; then
    printf '验收目录已保留：%s\n' "$smoke_workspace"
  else
    rm -rf "$smoke_root"
  fi
  exit "$smoke_status"
}
trap cleanup EXIT

bash "$repo_root/skills/forge-workspace/scripts/workspace.sh" verify
bash "$repo_root/skills/forge-workspace/scripts/workspace.sh" init --target "$smoke_workspace" --name smoke-app
cd "$smoke_workspace"
pnpm install --frozen-lockfile
for spec in 'shared-package utilities' 'react-app admin' 'nest-app worker'; do
  read -r kind project_name <<< "$spec"
  bash "$repo_root/skills/forge-workspace/scripts/workspace.sh" add --workspace "$smoke_workspace" --type "$kind" --name "$project_name"
done
pnpm install

node --input-type=module <<'JS'
import net from 'node:net';
import fs from 'node:fs';
const server = net.createServer();
await new Promise((resolve, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', resolve); });
const port = server.address().port;
await new Promise((resolve) => server.close(resolve));
fs.writeFileSync('.env', `DATABASE_URL=postgresql://forge:forge_local@127.0.0.1:${port}/smoke-app?schema=public\nPOSTGRES_PORT=${port}\n`);
JS

pnpm check
pnpm db:up
pnpm db:migrate
pnpm exec playwright install chromium
pnpm test:browser
pnpm test:system
node "$repo_root/scripts/audit-forge-runtime.mjs" "$smoke_workspace"
printf '完整验收通过：创建工作区、三种扩展、构建、类型、依赖边界、浏览器与数据库链路、开发监听和失败清理。\n'
