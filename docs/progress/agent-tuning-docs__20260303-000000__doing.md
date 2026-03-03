# agent-tuning 文档编写

- created_at: 20260303-000000

## 目标

为 agent-tuning skill 编写完整文档（index.md + design.md），文档完成后再编写 SKILL.md。

## 已完成

- `docs/agent-tuning/index.md`：概述、文件结构、工作流程、进度 checklist
- 与用户对齐设计方案：三角色（CodeAgent/TargetAgent/MetaAdvisor）、引导式内省、探索式分析、收窄职责边界（去掉测试搭建部分）
- 编写计划已审批（`.claude/plans/hidden-floating-lynx.md`）

## 下一步

- 编写 `docs/agent-tuning/design.md`：设计目标、核心概念、循环流程图、引导式内省设计、调优产物修改策略、终止条件、关键取舍（6 条）、风险表
- 编写 `skills/agent-tuning/SKILL.md`（文档完成后）
- 编写 `skills/agent-tuning/assets/introspection-prompt.md`（内省 prompt 模板）

## 阻塞

- 无

## 关键文件

- docs/agent-tuning/index.md
- docs/agent-tuning/design.md（待创建）
- .claude/plans/hidden-floating-lynx.md（计划文件）
- docs/session-reflect/design.md（取舍格式参考）
- docs/cross-review/design.md（流程图+风险表参考）
