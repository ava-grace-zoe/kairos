---
name: cross-review
description: 对技术方案或代码进行跨模型交叉评审。用户要求"交叉评审/cross review/多视角评审/让其他 agent 看看"时触发，通过 CLI 调用外部 code agent 独立评审同一方案，汇总共识与分歧。
---

# cross-review 执行规范

按以下三阶段执行，不跳步。

目标：调用与自身不同架构的外部 code agent 对同一方案独立评审，交叉对比发现盲区。

## 可用 Agent 列表

| Agent | CLI 命令 | 模型架构 | 关键参数 |
|-------|----------|---------|---------|
| Claude | `claude -p "{prompt}"` | Claude 系列 | `--output-format text` |
| Codex | `codex exec "{prompt}"` | GPT 系列 | `--full-auto` |

## 一、prepare — 准备评审上下文

1. 确定待评审内容：
   - 用户指定了文件路径 → 记录绝对路径，不拷贝。
   - 方案内容在对话中 → 写入 `$TMPDIR/.cross-review/<YYYYMMDD-HHMMSS>/context.md`。
2. 收集评审背景和关注点（用户未指定则使用默认维度）。
3. 在临时目录生成 `instructions.md`，内容：
   ```markdown
   # 评审任务

   ## 待评审文件
   - {绝对路径}

   ## 背景
   {方案要解决的问题}

   ## 关注点
   {用户指定或默认}

   ## 评审维度
   1. 正确性
   2. 可维护性
   3. 安全性
   4. 性能
   5. 遗漏

   ## 输出格式（严格遵守）
   ### [维度名]
   - **问题**: ...
   - **严重程度**: high/medium/low
   - **建议**: ...

   ### 总体评价
   {1-2 句话}
   ```

## 二、dispatch — 分发评审任务

### 分发逻辑

1. **自我识别** — 判断自身所属模型架构（如 Claude Code 内执行 → 自身为 Claude 系列）。
2. **排除自身** — 从可用 agent 列表中排除同架构 agent。
3. **可用性检测** — 对剩余 agent 执行 `which {cli}` 检测是否可用。
4. **分发执行** — 并行调用所有可用外部 agent。

### 兜底

- 无法确定自身身份 → 向用户列出所有可用 CLI 的 agent，由用户选择发送目标。

### 退化场景

- 仅一个外部 agent 可用 → 单 agent 评审，阶段三跳过交叉对比，直接输出结果。
- 无外部 agent 可用 → 提示用户安装至少一个外部 agent CLI，终止流程。

### 调用方式

对每个目标 agent，执行：
```bash
{cli_command} "阅读 {tmpdir}/instructions.md 中的评审任务并执行。将评审结果写入 {tmpdir}/review-{agent}.md" {关键参数}
```

并行调用，等待所有 agent 完成。若某 agent 超时或失败，跳过并在综合报告中标注。

## 三、synthesize — 综合分析

1. 读取临时目录下各 agent 的结果文件 `review-{agent}.md`（排除 `instructions.md`）。
2. 交叉对比各 agent 评审意见，分类整理：
   - **共识问题**：多个 agent 都提到 → 高优先级。
   - **分歧点**：仅单个 agent 提到 → 需人工判断。
   - **独特洞察**：某 agent 发现的其他 agent 遗漏的问题。
3. 生成 `{tmpdir}/synthesis.md`：
   ```markdown
   # 交叉评审综合报告

   ## 参与评审的 Agent
   - {实际参与的 agent 列表}

   ## 共识问题（高优先级）
   {多个 agent 共同指出的问题}

   ## 分歧点（需人工判断）
   {仅单个 agent 提出的问题}

   ## 独特洞察
   {值得关注的非共识发现}

   ## 行动建议
   {按优先级排序的改进项}
   ```

## 输出要求

执行完成后，向用户输出：

1. 参与评审的 agent 列表（含跳过原因）
2. 共识问题摘要（高优先级）
3. 分歧点（需用户判断）
4. 行动建议（按优先级排序）
5. 综合报告路径
