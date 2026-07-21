# agent-facing-design 操作手册

各审查维度的详细检查清单、prompt 模板和评估表以 `skills/agent-facing-design/references/` 为唯一权威来源（随 skill 分发）。本 runbook 只保留操作顺序和输出模板，不复制清单内容，避免双份维护漂移。

## 适用目标

- 面向 Agent 使用的 CLI、SDK 或脚本集合。
- `AGENTS.md`、`SKILL.md`、README、runbook 等 Agent-facing 文档。
- 多数据源汇聚工具的统一输出模型。
- 已存在但疑似腐化的工具文档。

## 前置输入

执行前收集：

1. 被测对象路径，例如 `AGENTS.md`、`skills/<name>/SKILL.md` 或 CLI 入口。
2. 目标 Agent 的能力边界：是否能运行命令、读代码、访问网络、访问生产环境。
3. 主要任务场景 3-5 个，使用业务目标描述，不使用子命令名暗示路径。
4. 如果是 CLI，准备 `--help` 输出和最常用命令示例。

## 操作顺序

按 `skills/agent-facing-design/SKILL.md` 的执行步骤走，各步骤的详细清单在对应 reference：

| 步骤 | 参考文档 |
|---|---|
| 1. CLI 自描述性与 Agent 适配输出审查 | `references/cli-design.md` 第 1-2 节（含成功/失败命令实测方法） |
| 2. 统一视图模型审查 | `references/cli-design.md` 第 3 节 |
| 3. 多脚本合并判断 | `references/cli-design.md` 第 4 节 |
| 4. Agent-facing 文档审查 | `references/docs-writing.md` |
| 5. Subagent 冒烟验收 | `references/smoke-test.md`（含隔离清单、Claude Code 启动方式、prompt 模板、评估表） |
| 6. 文档腐化审计 | `references/decay-audit.md`（含可直接执行的扫描命令） |

## 输出模板

```markdown
## 变更摘要

- 修改了什么：
- 修改原因：

## Subagent 验收结果

| 场景 | 结果 | 发现 |
| --- | --- | --- |
| 首次使用 | 通过 / 失败 | ... |
| 常规使用 | 通过 / 失败 | ... |
| 故障排查 | 通过 / 失败 | ... |

## 剩余风险

- 未覆盖场景：
- 尚未实测内容：
- 后续建议：
```
