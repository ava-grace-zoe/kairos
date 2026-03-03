# agent-tuning

基于 Langfuse 的引导式内省循环 Agent 配置调优 Skill——通过「调用 → 轨迹分析 → 内省 → 配置修改」循环，自动优化 TargetAgent 的系统提示词、工具描述和 few-shot 示例。

## 概述

- 这个 skill 是什么：基于 Langfuse 的 Agent 配置自动调优工具。CodeAgent 作为外层编排者，通过 e2e 测试驱动 + 引导式内省循环，迭代优化 TargetAgent 的行为配置。OTel 轨迹始终上报到 Langfuse，prompt 管理和轨迹获取各自支持 remote/local 两个通道。
- 解决什么问题：手动调试 Agent 提示词/工具配置效率低、缺乏系统性，改动难以归因，容易引入回归。
- 适用场景：
  - TargetAgent 在特定任务上行为不符合预期（遗漏工具调用、幻觉、格式偏差）
  - 需要系统化改进 Agent 的提示词、工具描述或 few-shot 示例
  - 调优对象为进程内模型调用，用户可指明入口文件
- 不适用场景：
  - 模型本身能力不足的任务（需要换模型而非调配置）
  - 无法构造可重复测试用例的场景
  - TargetAgent 是外部 API 服务（无法获取完整轨迹）

扩展文档：
- 设计文档：`design.md`

## 文件结构

```text
skills/agent-tuning/
├── SKILL.md              # 执行规范（含前置条件、接入指南、MetaAdvisor 调用方式）
└── assets/
    ├── project-probe.md         # 项目探查指南（定位入口/prompt/工具/few-shot）
    ├── manifest-template.md     # .agent-tuning/manifest.md 模板（用户声明项目结构）
    ├── introspection-prompt.md  # 引导式内省 prompt 模板
    ├── trace-format.md          # 轨迹摘要格式规范（Remote/Local → 统一文本）
    └── state-schema.md          # 调优状态 state.json 的 schema 和检测算法

docs/agent-tuning/
├── index.md              # 本文件
└── design.md             # 设计方案与关键取舍

examples/agent-tuning-test/  # 示例项目（天气 Agent）
├── src/
│   ├── instrument.ts     # OTel 初始化（Langfuse SpanProcessor）
│   ├── model.ts          # 统一模型调用接口（TargetAgent 和 MetaAdvisor 共享）
│   ├── config.ts         # Prompt 与 few-shot 配置（Local Prompt 通道）
│   ├── langfuse-client.ts # Langfuse 客户端（Remote Prompt 通道）
│   ├── agent.ts          # TargetAgent 定义（使用 model.ts）
│   ├── introspect.ts     # MetaAdvisor 内省调用（使用 model.ts）
│   ├── tracing.ts        # 本地轨迹收集工具（Local 轨迹通道）
│   ├── index.ts          # CLI 入口
│   └── test.ts           # 测试套件（支持 --json 输出 traceId）
├── .env.example          # 环境变量模板
└── package.json

# 用户项目中的约定目录（可选）
<project-root>/.agent-tuning/
├── manifest.md           # 项目结构声明（跳过探查）
└── test-cases.md         # 测试用例声明（跳过构造测试）

# 运行时产物（$TMPDIR/agent-tuning-<YYYYMMDD-HHMMSS>/）
$TMPDIR/agent-tuning-<YYYYMMDD-HHMMSS>/
├── state.json            # 调优状态（含 probeResult、轮次结果、检测数据）
├── snapshots/            # 配置快照（Local Prompt 通道回滚用）
│   └── round-NN/
├── traces/               # 本地轨迹文件（Local 轨迹通道）
│   └── round-NN.json
└── diffs/                # 配置变更 diff
    └── round-NN.diff
```

## 工作流程

### 1. 初始化

- 检测 `.agent-tuning/manifest.md`：
  - **存在** → 读取声明、验证文件存在性，跳过探查
  - **不存在** → 按 `project-probe.md` 探查项目（定位入口、追踪 prompt 来源、枚举工具、查找 few-shot、理解编排方式）
- 确定通道配置：Prompt 通道（Remote/Local）和轨迹通道（Remote/Local）
- 补齐未就绪的基础设施（OTel 初始化、测试脚本等）
- 构造 e2e 测试（或读取 `.agent-tuning/test-cases.md`）并校验有效性
- 初始化 state.json（含探查报告 probeResult）

### 2. 调优循环

- 调用 TargetAgent → 获取轨迹（Remote: Langfuse API / Local: onStepFinish 回调）
- CodeAgent 探索式分析轨迹，识别缺陷
- 有缺陷 → 引导式内省（MetaAdvisor 独立调用，同模型隔离上下文）
  → 内省回答「需要什么才能做对」
  → CodeAgent 修改配置（Remote Prompt: langfuse.prompt.create() / Local Prompt: 编辑配置文件）
  → 保存 diff 快照 → 回到循环起点
- 无缺陷 → 进入终止判断

### 3. 终止与产出

- CodeAgent 判断调优已收敛或达到循环上限（默认 5 轮）
- 输出：调优前后配置对比、每轮变更摘要、测试结果对比、Langfuse 链接

## 当前进度

- [x] 设计方案完成（design.md）— 含 Langfuse 集成 + 双通道架构 + mermaid 流程图
- [x] SKILL.md 执行规范 — 含前置条件、接入指南、伪代码骨架
- [x] 引导式内省 prompt 模板
- [x] 项目探查指南（project-probe.md）— 7 步系统化探查
- [x] Manifest 机制（manifest-template.md）— `.agent-tuning/` 约定目录 + 声明式跳过探查
- [x] 示例项目改造（examples/agent-tuning-test）— 配置分离 + OTel + 双通道
- [x] 初始化流程验证 — 在示例项目上完整走通 1.1-1.6
- [ ] 端到端验证（完整调优循环）

## 已知问题

- `@langfuse/otel` 和 `@langfuse/tracing` 要求 Node.js >= 20，bun 环境下有 peer dependency 警告但功能正常
- `@langfuse/tracing` 在 bun 环境下 `startActiveObservation` 会输出 `span.instrumentationScope.name` 错误到 stderr，不影响功能但日志嘈杂
- Langfuse prompt.get() 的 label 机制在 v4 SDK 中 API 可能有变化，需要在端到端验证时确认
- Langfuse 环境变量缺失时的降级策略需在 SKILL.md 中明确
