# agent-facing-design 讨论记录

## 决策记录

### 2026-07-01 标准文档补齐

- 主题：为 `agent-facing-design` 补齐标准 docs 目录。
- 背景：该 skill 已有 `SKILL.md`，但缺少 `docs/agent-facing-design/`，不符合仓库当前 skill 文档规范。
- 结论：
  - 新增 `index.md` 作为总览入口。
  - 新增 `design.md` 说明目标、方案、关键取舍、数据接口和风险。
  - 新增 `runbook.md` 作为实际审查和 subagent 冒烟验收操作手册。
  - 新增 `changelog.md` 记录本次文档补齐。
  - 暂不修改 `SKILL.md`，先保持执行合约稳定。
- 影响范围：`docs/agent-facing-design/`

### 2026-07-01 验收标准聚焦冷启动 Agent

- 主题：明确该 skill 的核心价值不是普通文档润色。
- 背景：面向人类的文档可以依赖跳读、搜索、背景知识和试错；Agent-facing 文档需要完整命令、默认值、输出路径、失败处理和前置条件。
- 结论：
  - 文档质量以“冷启动 Agent 能否完成任务”为标准。
  - `--help` 和文档必须形成可执行合同。
  - 使用隔离 subagent 验收，避免当前 Agent 的上下文补全能力掩盖文档缺陷。
- 影响范围：`design.md`、`runbook.md`

### 2026-07-03 SKILL.md 重组为执行合约 + references/ 下沉

- 主题：解决 SKILL.md 结构不达标、与 runbook.md 双份维护、以及两处腐化缺陷。
- 背景：盘点发现五类问题——(1) SKILL.md 是原则手册结构，缺前置条件、执行步骤和 design.md 链接，不符合仓库 skill 制作规范阶段 3 的完成标准；(2) subagent prompt 模板等内容在 SKILL.md 和 runbook.md 各存一份；(3) runbook.md 的行内代码扫描命令用双引号包反引号，触发 shell 命令替换，实测直接解析失败；(4) index.md 引用了全仓库不存在的 `agent-tool-contract`；(5) description 缺"腐化审计"类触发词。
- 结论：
  - SKILL.md 改为"前置条件 + 路由表 + 执行步骤 + 输出要求"的合约结构，补 design.md 链接，description 补触发词。
  - 检查清单下沉到 `skills/agent-facing-design/references/` 四个文件（cli-design / docs-writing / smoke-test / decay-audit），随 skill 分发；不放 `docs/` 因为 skills CLI 分发不带 docs 目录（见 design.md 取舍 5）。
  - runbook.md 去重，只保留操作顺序和输出模板，以 references/ 为唯一权威来源。
  - 腐化扫描命令改单引号并实测通过；移入 `references/decay-audit.md`。
  - index.md 悬空引用改为"相关专门 skill 尚未建立"。
  - 本决策同时关闭了原待决策事项 1（references/ 拆分）——已按方案落地。
- 影响范围：`skills/agent-facing-design/`、`docs/agent-facing-design/`

### 2026-07-03 冒烟验收在 Claude Code 下的落地方式

- 主题：把"隔离 subagent"从原则变成可执行指令。
- 背景：原 SKILL.md 要求"禁止 Read/Bash、用低级模型"，但没说在 Claude Code 里怎么启动这样的 subagent，执行者每次自行摸索——恰是本 skill 批评的文档缺陷类型。
- 结论：Agent 工具传 `model: "haiku"`；被测文档全文内联进 prompt（消除 Read 依赖）；prompt 显式禁止工具使用；回复中出现使用工具迹象即作废重跑。详见 `references/smoke-test.md` 第 2 节和 design.md 取舍 6。
- 影响范围：`references/smoke-test.md`

## 待决策事项

1. ~~是否需要新增 `references/checklist.md`~~（已于 2026-07-03 落地为四个 references 文件，见上方决策记录）

2. 是否需要脚本化文档腐化审计
- 问题：路径存在性、命令与 `--help` 对齐、临时 workaround 过期等检查可以部分自动化。
- 建议：等真实审查案例累计后，再判断是否新增 `scripts/audit-agent-docs.*`。

3. 与工具契约审查 skill 的边界
- 问题：tool description、参数 schema、tool result 也属于 Agent-facing 契约。
- 建议：本 skill 聚焦完整任务链路和文档 / CLI 自足性；字段级工具契约交给专门 skill。
