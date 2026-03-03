# agent-tuning 技能设计与基础设施

> 创建: 2026-03-03 00:00 | 更新: 2026-03-03 20:15

## 目标

为 agent-tuning skill 设计完整的执行规范和基础设施，使 CodeAgent 能基于 Langfuse 端到端运行"调用 → 轨迹分析 → 内省 → 配置修改"调优循环。

## 已完成

- **design.md 完整设计方案**：三角色架构、Langfuse 必选 + prompt/轨迹双通道独立选择、9 条关键取舍、10 项风险缓解
- **交叉评审**：Codex + Gemini 两个模型交叉评审并修订 design.md
- **SKILL.md 执行规范**：前置条件、通道选择、接入指南（含伪代码骨架）、MetaAdvisor 调用方式、配置验证方法、终止判断算法
- **introspection-prompt.md**：MetaAdvisor 内省 prompt 模板，含约束空间声明
- **trace-format.md**：轨迹摘要格式规范，Remote/Local 轨迹统一转换为文本格式，含 TypeScript 转换代码和长度控制规则
- **state-schema.md**：调优状态 state.json 完整 JSON schema + 回归/震荡/停滞三种检测算法 + probeResult 字段
- **示例项目改造**（examples/agent-tuning-test）：model.ts / introspect.ts / instrument.ts / config.ts / test.ts / tracing.ts，依赖安装完成
- **8 个缺口全部修复**：MetaAdvisor 调用方式、traceId 获取链路、轮次状态持久化、震荡检测定义、test.ts traceId 输出、配置验证方法、轨迹摘要格式、回归检测逻辑
- **project-probe.md 项目探查指南**：7 步系统化探查流程（定位入口 → 追踪 prompt 来源 → 枚举工具 → 查找 few-shot → 理解编排方式 → 检查就绪度 → 输出报告），覆盖 6 种 prompt 来源模式和 5 种编排类型
- **manifest 机制**：`.agent-tuning/` 约定目录 + `manifest.md` 声明式项目结构描述 + `test-cases.md` 测试用例声明。初始化阶段先检测该目录，有则读取跳过探查；无则探查后可选生成 manifest。manifest-template.md 提供完整 Markdown 模板
- **SKILL.md 初始化阶段重构**：6 个子阶段（1.1 项目探查含 manifest 检测 → 1.2 通道配置 → 1.3 构造测试含 test-cases.md 检测 → 1.4 测试有效性校验 → 1.5 创建工作目录 → 1.6 保留场景），修改配置步骤引用探查报告定位修改目标
- **初始化流程验证**：在示例项目上完整走通 1.1-1.6，确认 manifest 检测 → 探查 → 通道配置 → 测试运行 → state.json 初始化全链路通畅（2/3 pass，1 失败符合预期）
- **design.md mermaid 流程图**：数据流图 + 完整循环流程图（含 manifest 分支、探查、终止判断、回归回滚），替换旧 ASCII 图
- **index.md 对齐**：文件结构补充 project-probe.md / manifest-template.md / .agent-tuning/ 约定目录，工作流程对齐 manifest 检测 + 探查步骤，更新进度和已知问题
- **文档一致性修复**：SKILL.md 辅助资源表 .yaml → .md 修正

## 进行中

- 无

## 待办

- [ ] 修复 SKILL.md 1.2：Langfuse 环境变量缺失时的降级策略（轨迹通道自动降级为 Local）
- [ ] 修复 SKILL.md 1.3：先检查项目是否已有测试脚本再决定是否构造
- [ ] 修复 SKILL.md 1.5：明确 Local Prompt 通道快照应保存的文件范围
- [ ] 对齐 design.md "各阶段详解 → 1. 初始化"：与 SKILL.md 1.1-1.6 对齐（加入 manifest 检测 + project-probe）
- [ ] 修复 SKILL.md 前置条件：Langfuse 列为"必选"但 instrument.ts 实际做了优雅降级，矛盾需澄清
- [ ] 端到端验证：使用示例项目在真实 Langfuse 环境跑完整调优循环
- [ ] 验证 @langfuse/tracing 的 startActiveObservation + getActiveTraceId 在 bun 环境下的兼容性

## 关键发现

**架构核心决策：Langfuse 必选 + 双通道独立选择**
- Langfuse 是必选基座（OTel 上报始终开启），但 Prompt 管理和轨迹获取是两个独立维度，各自支持 remote/local 通道
- 四种组合中实际常用两种：全 Remote（成熟项目）、Local Prompt + Remote 轨迹（Prompt 在代码仓库管理的项目）

**manifest 机制：convention-over-configuration**
- `.agent-tuning/manifest.md` 类似 `.eslintrc` / `tsconfig.json` 的约定目录模式
- 用户用 Markdown（而非 YAML）声明项目结构，消费者是 LLM 不是解析器，Markdown 可以附带上下文说明
- 探查完成后可选生成 manifest，下次调优同一项目跳过探查

**初始化流程验证发现的问题**
- Langfuse 环境变量缺失时 instrument.ts 优雅降级不报错，但 Remote 轨迹通道实际不可用 → 需要降级策略
- @langfuse/tracing 在 bun 环境下 startActiveObservation 会输出 `span.instrumentationScope.name` 错误到 stderr，不影响功能
- 已有测试脚本的项目应先复用再决定是否构造，SKILL.md 缺少此逻辑

**统一模型调用接口**
- TargetAgent 和 MetaAdvisor 共享同一个 model 实例和 call() 函数
- 区别仅在于输入：TargetAgent 带 system prompt + tools；MetaAdvisor 只带组装后的内省 prompt

**终止检测算法**
- 回归：对比 N 和 N-1 轮的 tests 数组，pass→fail 即回归
- 震荡：同一测试最近 3 轮 pass 序列出现 [T,F,T] 或 [F,T,F]
- 停滞：连续 2 轮所有测试 pass/fail 完全相同

## 相关文件

- skills/agent-tuning/SKILL.md
- skills/agent-tuning/assets/project-probe.md
- skills/agent-tuning/assets/manifest-template.md
- skills/agent-tuning/assets/introspection-prompt.md
- skills/agent-tuning/assets/trace-format.md
- skills/agent-tuning/assets/state-schema.md
- docs/agent-tuning/design.md
- docs/agent-tuning/index.md
- examples/agent-tuning-test/src/model.ts
- examples/agent-tuning-test/src/introspect.ts
- examples/agent-tuning-test/src/agent.ts
- examples/agent-tuning-test/src/instrument.ts
- examples/agent-tuning-test/src/config.ts
- examples/agent-tuning-test/src/test.ts
- examples/agent-tuning-test/src/tracing.ts
- examples/agent-tuning-test/.env.example
