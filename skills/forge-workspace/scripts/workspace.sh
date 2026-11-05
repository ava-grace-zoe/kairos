#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v node >/dev/null 2>&1; then
  echo '缺少 Node.js，请安装 22.23.2 或支持的更高偶数版本后重试。' >&2
  exit 1
fi
exec node "$script_dir/workspace.mjs" "$@"
