# agent-facing-design 变更日志

记录影响 `agent-facing-design` 文档、执行边界和验收流程的变化。

---

## [v0.2.0] - 2026-07-03

### 变更

- `SKILL.md` 重组为执行合约结构：前置条件 + 对象类型路由表 + 执行步骤 + 输出要求；补充指向 `design.md` 的链接；description 补充腐化审计、文档过期等触发词。
- 检查清单从 `SKILL.md` 下沉到 `skills/agent-facing-design/references/`（cli-design.md、docs-writing.md、smoke-test.md、decay-audit.md），随 skill 分发。
- `runbook.md` 去重：不再复制清单和模板，只保留操作顺序和输出模板，以 `references/` 为唯一权威来源。

### 修复

- 腐化审计的行内代码扫描命令：双引号包反引号触发 shell 命令替换导致解析失败（实测复现），改为单引号并实测通过；命令移至 `references/decay-audit.md`。
- `index.md` 移除对不存在的 `agent-tool-contract` skill 的悬空引用。

### 新增

- `references/smoke-test.md` 第 2 节：Claude Code 下启动隔离 subagent 的具体方式（haiku 模型、文档内联、prompt 工具禁令、结果有效性自查）。
- `cases.md`：首个冒烟验收回归案例（被测对象：progress-manager 文档集）。

## [v0.1.0] - 2026-07-01

### 新增

- 补齐标准文档目录 `docs/agent-facing-design/`。
- 新增 `index.md`：说明 skill 目标、适用场景、文件结构、工作流程、当前进度和已知问题。
- 新增 `design.md`：说明 Agent-facing 工具 / 文档设计目标、关键取舍、数据接口和风险缓解。
- 新增 `discussion.md`：记录文档补齐和冷启动 Agent 验收标准的决策。
- 新增 `runbook.md`：提供 CLI 审查、Agent 文档审查、统一视图模型审查、subagent 冒烟验收和腐化审计步骤。

### 未变更

- 未修改 `skills/agent-facing-design/SKILL.md`。
- 未新增脚本或 assets。
