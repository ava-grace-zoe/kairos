#!/usr/bin/env bash
set -euo pipefail

AGENTS_DIR="$HOME/.agents"
REFLECT_DIR="$AGENTS_DIR/session-reflect"
PROFILE_FILE="$REFLECT_DIR/profile.md"
CONTEXT_SOURCE_FILE="$REFLECT_DIR/context.md"
CONTEXT_ENTRY_FILE="$AGENTS_DIR/context.md"
HISTORY_FILE="$REFLECT_DIR/history.md"
WORKFLOW_CANDIDATES_FILE="$REFLECT_DIR/workflow-candidates.md"

exists_or_link() {
  [ -e "$1" ] || [ -L "$1" ]
}

create_profile() {
  cat > "$PROFILE_FILE" << 'EOF'
# User Profile

## 协作画像

暂无数据，完成首次会话反思后自动生成。

## 工程偏好

暂无数据。

## 思维与决策模式

暂无数据。

## 风险线索

暂无数据。

## 证据索引

暂无数据。
EOF
}

create_context() {
  cat > "$CONTEXT_SOURCE_FILE" << 'EOF'
# Agent Context

## 沟通策略

暂无数据。

## 调查与决策策略

暂无数据。

## 执行与验证策略

暂无数据。

## 防错策略

暂无数据。

## 硬性禁区

暂无数据。
EOF
}

create_workflow_candidates() {
  cat > "$WORKFLOW_CANDIDATES_FILE" << 'EOF'
# Workflow Candidates

## 候选规则

- 单次会话内重复出现：记录为 candidate。
- 跨会话出现 2 次：状态可升级为 recommended。
- 跨会话出现 3 次且输入输出稳定：强建议创建 skill、脚本或 runbook。
- 项目私有流程标为 project-local，不推荐创建全局 skill，除非能抽象为跨项目模式。
- 用户拒绝后标为 rejected，后续只在出现明显新证据时再提。

## Candidates

暂无候选。
EOF
}

create_history() {
  touch "$HISTORY_FILE"
}

ensure_file() {
  local file="$1"
  local create_fn="$2"

  if exists_or_link "$file"; then
    echo "[ok] $file 已存在，跳过初始化"
  else
    "$create_fn"
    echo "[ok] 已创建 $file"
  fi
}

ensure_context_entry() {
  if [ -L "$CONTEXT_ENTRY_FILE" ]; then
    local current_target
    current_target="$(readlink "$CONTEXT_ENTRY_FILE")"

    if [ "$current_target" = "$CONTEXT_SOURCE_FILE" ]; then
      echo "[ok] $CONTEXT_ENTRY_FILE 已指向 $CONTEXT_SOURCE_FILE"
      return 0
    fi

    echo "[warn] $CONTEXT_ENTRY_FILE 已是软链接，但指向 $current_target，未修改"
    return 1
  fi

  if exists_or_link "$CONTEXT_ENTRY_FILE"; then
    echo "[warn] $CONTEXT_ENTRY_FILE 已存在且非软链接，未覆盖"
    echo "[warn] 请先人工迁移旧内容，再将它改为指向 $CONTEXT_SOURCE_FILE"
    return 1
  fi

  ln -s "$CONTEXT_SOURCE_FILE" "$CONTEXT_ENTRY_FILE"
  echo "[ok] 已创建软链接 $CONTEXT_ENTRY_FILE -> $CONTEXT_SOURCE_FILE"
  return 0
}

link_if_dir_exists() {
  local target_dir="$1"
  local target_file="$2"
  local name="$3"

  if [ ! -d "$target_dir" ]; then
    echo "[skip] $name: $target_dir 不存在"
    return
  fi

  if [ -L "$target_file" ]; then
    echo "[ok] $name: $target_file 软链接已存在"
  elif exists_or_link "$target_file"; then
    echo "[warn] $name: $target_file 已存在且非软链接，请手动合并"
  else
    ln -s "$CONTEXT_ENTRY_FILE" "$target_file"
    echo "[ok] $name: 已创建软链接 $target_file -> $CONTEXT_ENTRY_FILE"
  fi
}

mkdir -p "$AGENTS_DIR" "$REFLECT_DIR"

ensure_file "$PROFILE_FILE" create_profile
ensure_file "$CONTEXT_SOURCE_FILE" create_context
ensure_file "$HISTORY_FILE" create_history
ensure_file "$WORKFLOW_CANDIDATES_FILE" create_workflow_candidates

if ensure_context_entry; then
  link_if_dir_exists "$HOME/.claude" "$HOME/.claude/CLAUDE.md" "Claude Code"
  link_if_dir_exists "$HOME/.codex" "$HOME/.codex/AGENTS.md" "Codex CLI"
  link_if_dir_exists "$HOME/.gemini" "$HOME/.gemini/GEMINI.md" "Gemini"
else
  echo "[warn] 跳过 Claude/Codex/Gemini 软链接创建，避免指向未迁移的 context 入口"
fi

echo ""
echo "Done."
