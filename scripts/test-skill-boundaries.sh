#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="$repo_root/scripts/check-skill-boundaries.sh"

bash "$checker" "$repo_root" >/dev/null

fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT
mkdir -p "$fixture_root/skills/example"
printf '%s\n' '详见：`docs/example/guide.md`' > "$fixture_root/skills/example/SKILL.md"

if bash "$checker" "$fixture_root" >/dev/null 2>&1; then
  echo "[error] checker accepted a repository-level docs dependency" >&2
  exit 1
fi

echo "[ok] skill runtime boundary tests"
