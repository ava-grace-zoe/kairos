#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if violations=$(rg -n '(设计文档|参考|详见).*?(\.\./)*docs/|\]\((\.\./)*docs/' "$repo_root/skills" -g 'SKILL.md'); then
  echo "[error] runtime SKILL.md must not depend on repository-level docs" >&2
  printf '%s\n' "$violations" >&2
  exit 1
fi

echo "[ok] skill runtime boundaries"
