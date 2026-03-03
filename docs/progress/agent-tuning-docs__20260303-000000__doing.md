# agent-tuning 文档与基础设施重构

- created_at: 20260303-000000
- updated_at: 20260303-1830

## 目标

为 agent-tuning skill 编写完整文档并构建基于 Langfuse 的调优基础设施（Langfuse 必选 + prompt/轨迹各自支持 remote/local 通道），同时提供可复用的示例代码和伪代码骨架，确保 CodeAgent 能端到端跑通完整调优循环。

## 已完成

- `docs/agent-tuning/index.md`：概述、文件结构、工作流程、进度 checklist
- `docs/agent-tuning/design.md`：完整设计方案，含基础设施层（Langfuse + 双通道）、traceId 获取链路、MetaAdvisor 调用方式、轨迹摘要格式、调优状态持久化、检测算法
- 交叉评审（Codex + Gemini），根据评审意见修订
- `skills/agent-tuning/SKILL.md`：完整执行规范，含：
  - 前置条件、通道选择机制
  - 接入指南（伪代码骨架）
  - 辅助资源表（内省模板 / 轨迹格式 / 状态 schema）
  - MetaAdvisor 调用方式（独立 generateText 调用伪代码）
  - 配置验证方法（import 检查 / prompt.get 验证）
  - 终止判断算法（回归/震荡/停滞的可操作定义）
  - traceId 获取链路（startActiveObservation + getActiveTraceId）
  - state.json 初始化和每轮更新
- `skills/agent-tuning/assets/introspection-prompt.md`：内省 prompt 模板
- `skills/agent-tuning/assets/trace-format.md`：轨迹摘要格式规范 + Remote/Local 转换代码
- `skills/agent-tuning/assets/state-schema.md`：调优状态 JSON schema + 回归/震荡/停滞检测算法
- `examples/agent-tuning-test/` 改造完成：
  - `src/instrument.ts`：OTel 初始化
  - `src/config.ts`：Prompt 配置分离
  - `src/langfuse-client.ts`：Langfuse 客户端
  - `src/tracing.ts`：本地轨迹收集
  - `src/agent.ts`：TargetAgent
  - `src/test.ts`：测试套件（支持 `--json` 输出 traceId、`--local-traces` 本地轨迹保存）
  - `.env.example`

## 缺口修复记录

| 缺口 | 修复方式 |
|------|---------|
| MetaAdvisor "独立调用"不具体 | SKILL.md 新增"MetaAdvisor 调用方式"章节 + generateText 伪代码 |
| traceId 获取方式不明 | 引入 `@langfuse/tracing` 的 `startActiveObservation` + `getActiveTraceId()`，test.ts 实现，SKILL.md 和 design.md 文档化 |
| 轮次状态无持久化 | 创建 `assets/state-schema.md`，定义 state.json 完整 schema |
| 震荡检测定义模糊 | state-schema.md 中给出精确算法：最近 3 轮 pass 序列模式匹配 |
| test.ts 不输出 traceId | test.ts 重写：startActiveObservation 包裹、--json 输出、TestResult 结构体含 traceId |
| 配置验证方法不明 | SKILL.md 2.4 步骤 3 给出具体验证命令 |
| 轨迹填入内省 prompt 格式未定义 | 创建 `assets/trace-format.md`，含统一格式定义 + Remote/Local 转换代码 + 长度控制规则 |
| 回归检测无判断逻辑 | state-schema.md 中给出算法：对比 N 和 N-1 的 tests 数组 |

## 待办

- [ ] 端到端验证（使用示例项目运行完整调优循环）

## 关键文件

- docs/agent-tuning/index.md
- docs/agent-tuning/design.md
- skills/agent-tuning/SKILL.md
- skills/agent-tuning/assets/introspection-prompt.md
- skills/agent-tuning/assets/trace-format.md
- skills/agent-tuning/assets/state-schema.md
- examples/agent-tuning-test/src/instrument.ts
- examples/agent-tuning-test/src/config.ts
- examples/agent-tuning-test/src/langfuse-client.ts
- examples/agent-tuning-test/src/tracing.ts
- examples/agent-tuning-test/src/agent.ts
- examples/agent-tuning-test/src/test.ts
- examples/agent-tuning-test/.env.example
