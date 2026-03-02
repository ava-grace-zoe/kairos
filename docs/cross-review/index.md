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
└── SKILL.md

docs/cross-review/
├── index.md                   # 本文件
└── design.md                  # 设计方案

# 运行时产物（仅降级场景，$TMPDIR/cross-review-<YYYYMMDD-HHMMSS>/）
$TMPDIR/cross-review-<YYYYMMDD-HHMMSS>/
└── context.md                 # 仅对话内容超长时创建
```

## 工作流程

### 1. 准备 + 分发

- 输入：用户触发评审请求
- 处理：
  1. 收集最小充分评审上下文（被评审对象 + 决策背景 + 必要依赖），主动从代码库/对话历史补充
  2. 根据待评审内容性质推导关注点，补充用户指定的关注点
  3. 识别自身架构，排除同架构 agent，检测可用外部 agent CLI
  4. 构建 prompt 调用外部 agent，stdout 捕获结果
- 降级：上下文超长时落临时文件；stdout 不可靠时改文件回传

### 2. 综合输出

- 输入：外部 agent 返回的评审结果
- 处理：对比各 agent 结果，在对话中直接输出
  - **共识问题**（多个 agent 共同指出 → 高优先级）
  - **分歧点**（仅单个 agent 提出 → 需用户判断）
  - **行动建议**（按优先级排序）
- 退化：仅一个外部 agent 可用时，输出该 agent 结果 + 自身判断

## 当前进度

- [x] 设计方案完成（v2：两阶段 + stdout 优先）
- [x] Agent 分发规则设计
- [x] SKILL.md 实现
- [x] codex exec 调用验证
- [ ] SKILL.md 对齐 design v2
- [ ] claude -p 调用验证
- [ ] 多 agent 交叉对比验证

## 已知问题

1. 问题描述：外部 agent CLI 可用性依赖用户环境
   - 影响范围：分发阶段可能失败
   - 临时规避：`command -v` 检测，不可用则跳过并提示

2. 问题描述：prompt 内联方式存在 argv 长度限制
   - 影响范围：超长上下文场景
   - 临时规避：降级为临时文件引用
