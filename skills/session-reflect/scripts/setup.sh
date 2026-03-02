#!/bin/bash

AGENTS_DIR="$HOME/.agents"
CONTEXT_FILE="$AGENTS_DIR/context.md"
HISTORY_FILE="$AGENTS_DIR/history.md"

# 1. 创建目录
mkdir -p "$AGENTS_DIR"

# 2. 初始化 context.md（不覆盖已有文件）
if [ -f "$CONTEXT_FILE" ]; then
  echo "✓ $CONTEXT_FILE 已存在，跳过初始化"
else
  cat > "$CONTEXT_FILE" << 'EOF'
# User Context

## 基本信息

- 名称：
- 主要语言：
- 常用技术栈：
- 沟通语言：简体中文

## 综合画像

### 协作风格

暂无数据，完成首次会话反思后自动生成。

### 思维模式

暂无数据，完成首次会话反思后自动生成。

## AI 应对指南

### 行为校准

暂无数据。

### 认知防护

暂无数据。

### 硬性禁区

暂无数据。

## 偏好与习惯

暂无数据。
EOF
  echo "✓ 已创建 $CONTEXT_FILE"
fi

# 3. 初始化 history.md（不覆盖已有文件）
if [ -f "$HISTORY_FILE" ]; then
  echo "✓ $HISTORY_FILE 已存在，跳过初始化"
else
  touch "$HISTORY_FILE"
  echo "✓ 已创建 $HISTORY_FILE"
fi

# 4. 创建软链接
link_if_dir_exists() {
  local target_dir="$1"
  local target_file="$2"
  local name="$3"

  if [ ! -d "$target_dir" ]; then
    echo "⊘ $name: $target_dir 不存在，跳过"
    return
  fi

  if [ -L "$target_file" ]; then
    echo "✓ $name: 软链接已存在"
  elif [ -f "$target_file" ]; then
    echo "⚠ $name: $target_file 已存在且非软链接，请手动处理"
  else
    ln -s "$CONTEXT_FILE" "$target_file"
    echo "✓ $name: 已创建软链接 $target_file"
  fi
}

link_if_dir_exists "$HOME/.claude"  "$HOME/.claude/CLAUDE.md"   "Claude Code"
link_if_dir_exists "$HOME/.codex"   "$HOME/.codex/AGENTS.md"    "Codex CLI"
link_if_dir_exists "$HOME/.gemini"  "$HOME/.gemini/GEMINI.md"   "Anti/Gemini"

echo ""
echo "Done."
