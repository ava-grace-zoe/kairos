# agent-facing-design

面向 Agent 消费的工具、CLI 和文档设计审查 skill。核心验收标准是：冷启动 Agent 只凭文档、`--help` 和命令输出，能否独立完成任务。

## 概述

- 这个 skill 是什么：用于设计、审查和改进 Agent-facing 工具、命令行接口、SDK、AGENTS.md、SKILL.md 和 runbook。
- 解决什么问题：避免工具和文档只对人类"看起来能懂"，但对 Agent 缺少完整命令、输出路径、错误恢复、默认值和机器可读结果。
- 适用场景：
  - 新建或重构给 Agent 使用的 CLI / SDK。
  - 审查 `AGENTS.md`、`SKILL.md`、runbook 或工具文档是否足够自包含。
  - 将多个散落脚本合并为统一 CLI 入口。
  - 为多数据源工具设计统一输出视图模型。
  - 做文档腐化审计，检查路径、命令、参数和示例是否过期。
- 不适用场景：
  - 纯人类产品文案润色。
  - 只审查视觉界面或交互美感。
  - 不涉及 Agent 消费边界的普通代码重构。
  - 需要保存项目进度的场景；这类任务应使用 `progress-manager`。

## 文件结构

```text
skills/agent-facing-design/
├── SKILL.md                     # 执行合约：前置条件 + 路由 + 执行步骤
└── references/
    ├── cli-design.md            # 工具设计原则（CLI 自描述性、Agent 适配输出、数据模型收敛、合并脚本）
    ├── docs-writing.md          # Agent-facing 文档编写原则
    ├── smoke-test.md            # Subagent 冒烟验收（隔离原则、Claude Code 启动方式、评估标准）
    └── decay-audit.md           # 文档腐化审计（含扫描命令）

docs/agent-facing-design/
├── index.md
├── design.md
├── discussion.md
├── changelog.md
├── runbook.md
└── cases.md                     # 冒烟验收回归案例记录
```

检查清单放在 `skills/agent-facing-design/references/` 而非 `docs/`，因为 skills CLI 分发时只安装 skill 目录，`docs/` 不随包分发。

## 工作流程

1. **输入识别与路由**：确认被审查对象类型（CLI、SDK、文档、视图模型、脚本合并、腐化审计），按 SKILL.md 中的路由表读取对应 reference。
2. **Agent 消费边界定义**：明确目标 Agent 能拿到什么信息、能不能运行命令、是否能读代码、是否需要跨环境执行；未说明时按最受限假设审查。
3. **审查与整改**：按命中的 reference 逐项检查；能实测的项优先实测，不能实测的标注"从文档推断"。
4. **Subagent 冒烟验收**：设计 3-5 个业务目标场景，用隔离的低级模型 subagent 只凭原始文档推演命令序列，验证文档是否自足。文档类对象整改后必做。
5. **输出整改结果**：给出变更摘要、验收结果、剩余风险和后续补强建议。

## 当前进度

- [x] 核心执行规范已在 `SKILL.md` 中实现。
- [x] 覆盖 CLI 自描述性、Agent 适配输出、统一视图模型、脚本合并、Agent-facing 文档、subagent 冒烟验收和文档腐化审计。
- [x] 标准文档目录已补齐。
- [x] SKILL.md 重组为执行合约结构，检查清单下沉到 `references/`（2026-07-03）。
- [x] 冒烟验收补齐 Claude Code 下的隔离 subagent 启动指令（2026-07-03）。
- [x] 已基于真实对象（progress-manager 文档集）执行首轮 subagent 冒烟验收，案例见 `cases.md`（2026-07-03）。
- [ ] 回归案例累计到 3-5 个。
- [ ] 腐化审计的路径存在性检查脚本化。

## 已知问题

1. **冒烟验收的工具禁令依赖 prompt 约束**
- 影响范围：Claude Code 的 Agent 工具无法逐调用裁剪 subagent 工具集，工具禁令靠 prompt 声明 + 结果自查兜底。
- 临时规避：按 `references/smoke-test.md` 第 2 节执行文档内联和结果有效性自查。
- 后续计划：若平台支持逐调用工具白名单，改为硬性裁剪。

2. **与工具字段级契约审查存在边界重叠**
- 影响范围：tool description、参数 schema、tool result 结构等字段级问题，与本 skill 的任务链路审查有重叠。
- 临时规避：本 skill 关注 Agent 能否凭文档完成完整任务；字段级契约暂不展开（相关专门 skill 尚未建立，见 discussion.md 待决策事项 3）。
- 后续计划：若建立专门的工具契约审查 skill，再明确协作边界。

3. **回归案例样本不足**
- 影响范围：目前只有 1 个真实案例（cases.md），规范仍以经验归纳为主。
- 临时规避：每次审查时记录失败场景和修复点。
- 后续计划：累计到 3-5 个标准案例后回头校准检查清单。
