# cross-review

通过 CLI 调用外部 code agent（claude、codex）对技术方案进行独立交叉评审，汇总多视角反馈。

## 概述

- 这个 skill 是什么：跨 code agent 交叉评审工具，利用 `claude -p` / `codex exec` 调用外部 agent 独立评审同一方案
- 解决什么问题：单一 agent 评审存在视角盲区，交叉评审可发现共识问题和独特洞察
- 适用场景：
  - 技术设计方案评审（design doc、架构决策、API 设计）
  - 代码实现评审（关键模块、核心算法）
  - 任何需要多视角反馈的方案
- 不适用场景：
  - 简单代码修改（单行 fix、typo）
  - 不涉及设计决策的机械性任务

## 文件结构

```text
skills/cross-review/
├── SKILL.md
└── assets/
    └── review-prompt.md       # 评审指令模板

docs/cross-review/
├── index.md                   # 本文件
└── design.md                  # 设计方案

# 运行时产物（$TMPDIR/.cross-review/，系统重启自动清理）
$TMPDIR/.cross-review/<YYYYMMDD-HHMMSS>/
├── context.md                 # 仅对话内容时创建
├── instructions.md            # 评审指令（路径引用 + 维度 + 格式）
├── review-claude.md           # claude 评审结果
├── review-codex.md            # codex 评审结果
└── synthesis.md               # 综合分析报告
```

## 工作流程

### 1. prepare — 准备评审上下文

- 输入：待评审文件路径（或对话中的方案内容）+ 评审背景 + 关注点
- 处理：
  - 方案已在文件系统 → 直接记录绝对路径，不拷贝
  - 方案来自对话 → 写入 `$TMPDIR/.cross-review/<YYYYMMDD-HHMMSS>/context.md`
  - 在临时目录生成 `instructions.md`（包含文件路径引用、评审维度、输出格式）
- 产物：`$TMPDIR/.cross-review/<YYYYMMDD-HHMMSS>/instructions.md`

### 2. dispatch — 分发评审任务

- 输入：`instructions.md` 路径
- 处理：
  1. 自我识别 — 判断当前执行环境所属模型架构
  2. 排除自身 — 从可用 agent 列表中排除同架构 agent
  3. 可用性检测 — 检测剩余 agent 的 CLI 是否存在
  4. 无法确定自身身份时 → 向用户确认发送目标
  5. 并行调用所有可用外部 agent CLI
- 产物：`review-{agent}.md`（每个 agent 一个）
- 关键：prompt ~30 字，上下文全部通过文件路径引用传递
- 退化：仅一个可用 → 单 agent 评审；全不可用 → 终止并提示

### 3. synthesize — 综合分析

- 输入：所有 `review-*.md` 文件
- 处理：交叉对比各 agent 评审意见
  - **共识点**：多个 agent 都提到 → 高优先级
  - **分歧点**：仅单个 agent 提到 → 需人工判断
  - **独特洞察**：某 agent 发现的其他 agent 遗漏的问题
- 产物：`synthesis.md` 综合报告 + 向用户输出摘要

## 当前进度

- [x] 设计方案完成
- [x] Agent 分发规则设计
- [x] SKILL.md 实现
- [x] review-prompt.md 模板
- [x] codex exec 调用验证
- [x] context.md 传递验证
- [ ] claude -p 调用验证
- [ ] 多 agent 交叉对比验证（synthesize 阶段）

## 已知问题

1. 问题描述：外部 agent CLI 可用性依赖用户环境
   - 影响范围：dispatch 阶段可能失败
   - 临时规避：dispatch 前检测 CLI 是否存在，不可用则跳过并提示

2. 问题描述：外部 agent 对文件系统的访问权限
   - 影响范围：agent 可能无法读取指令文件或写入结果文件
   - 临时规避：codex 需要 `--full-auto`；claude -p 默认有读权限
