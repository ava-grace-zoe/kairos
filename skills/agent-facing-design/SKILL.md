---
name: agent-facing-design
description: 设计、审查或改进面向 Agent 消费的工具、CLI、SDK 或文档（AGENTS.md、SKILL.md、runbook、README）。用户提及"给 agent 用的工具/文档""agent 能不能用这个""文档够不够 agent 理解"，或要求做文档腐化审计、检查文档/命令/路径是否过期、合并多个脚本为统一 CLI、设计跨数据源的统一视图模型时触发。
---

# agent-facing-design 执行规范

核心前提：Agent 消费的工具和文档，验收标准不是"人能读懂"，而是"一个能力受限的 Agent 仅凭文档能独立完成任务"。

## 前置条件

- 已明确被测对象：CLI 入口、文档文件路径或脚本集合。
- 已明确目标 Agent 的能力边界：能否运行命令、读代码、访问网络或生产环境。用户未说明时，按最受限假设（只有文档，不能跑命令）审查。
- 若要实测 CLI 行为，本地能运行对应命令。

## 执行步骤

### 1. 输入识别与路由

确认被审查对象类型，按下表读取对应参考文档；一次任务可命中多行：

| 被审查对象 | 读取的参考文档 |
|---|---|
| CLI / SDK / 脚本集合 | [references/cli-design.md](references/cli-design.md) |
| 多脚本是否合并为统一 CLI | [references/cli-design.md](references/cli-design.md) 第 4 节 |
| 多数据源统一视图模型 | [references/cli-design.md](references/cli-design.md) 第 3 节 |
| AGENTS.md / SKILL.md / runbook 等文档 | [references/docs-writing.md](references/docs-writing.md) |
| 已有文档的过期 / 腐化检查 | [references/decay-audit.md](references/decay-audit.md) |

### 2. Agent 消费边界定义

明确目标 Agent 能拿到什么信息、能不能运行命令、是否能读代码、是否跨环境执行。审查结论必须相对这个边界给出——同一份文档，对"能跑 `--help` 的 Agent"和"只有文档的 Agent"的自足性要求不同。

### 3. 审查与整改

按命中的参考文档逐项检查，输出问题清单；用户要求修改时直接整改。能实测的项（退出码、流分离、help 行为）优先实测，不能实测的标注"从文档推断"。

### 4. Subagent 冒烟验收

按 [references/smoke-test.md](references/smoke-test.md) 执行：设计 3-5 个业务目标场景，用隔离的低级模型 subagent 只凭文档原文推演命令序列，按评估表判定缺陷并修复。

- 文档类对象（AGENTS.md / SKILL.md / runbook）整改后**必做**。
- 纯 CLI 行为修改（如修退出码）可跳过，但要在剩余风险中注明未做冒烟验收。

### 5. 输出结果

执行完成后，输出：

1. **变更摘要**：改了什么、为什么改。
2. **Subagent 验收结果**：每个场景的通过/失败状态和关键发现；未执行时说明原因。
3. **剩余风险**：未覆盖的场景或已知的文档薄弱点。

所有结论区分"已实测""从文档推断""尚未验证"。

## 辅助资源

- [references/cli-design.md](references/cli-design.md)：工具设计原则（CLI 自描述性、Agent 适配输出、数据模型收敛、合并脚本判断）
- [references/docs-writing.md](references/docs-writing.md)：Agent-facing 文档编写原则
- [references/smoke-test.md](references/smoke-test.md)：Subagent 冒烟验收（隔离原则、Claude Code 启动方式、场景设计、评估标准）
- [references/decay-audit.md](references/decay-audit.md)：文档腐化审计
