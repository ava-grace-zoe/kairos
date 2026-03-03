# agent-tuning

引导式内省循环驱动的 Agent 自适应调优 Skill——通过反复「调用 → 捕获轨迹 → 分析缺陷 → 内省 → 修改配置」循环，自动优化 TargetAgent 的系统提示词、工具描述和 few-shot 示例。

## 概述

- 这个 skill 是什么：Agent 配置自动调优工具。CodeAgent 作为外层编排者，通过 e2e 测试驱动 + 引导式内省循环，迭代优化 TargetAgent 的行为配置。
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
├── SKILL.md              # 执行规范
└── assets/
    └── introspection-prompt.md  # 引导式内省 prompt 模板

docs/agent-tuning/
├── index.md              # 本文件
└── design.md             # 设计方案与关键取舍

# 运行时产物（$TMPDIR/agent-tuning-<YYYYMMDD-HHMMSS>/）
$TMPDIR/agent-tuning-<YYYYMMDD-HHMMSS>/
├── snapshots/            # 每轮配置快照（用于回滚）
│   └── round-NN/
├── traces/               # 每轮轨迹
│   └── round-NN.json
└── diffs/                # 每轮配置变更 diff
    └── round-NN.diff
```

## 工作流程

### 1. 初始化

- 输入：用户指明 TargetAgent 入口文件（或 CodeAgent 自行探索代码库），以及待调优的测试场景描述
- 处理：定位 TargetAgent 调用入口、识别现有配置文件（系统提示词/工具定义/few-shot），构造 e2e 测试

### 2. 调优循环

- 调用 TargetAgent → 捕获完整运行轨迹
- CodeAgent 探索式分析轨迹，识别缺陷
- 有缺陷 → 引导式内省（MetaAdvisor 独立调用，同模型隔离上下文）
  → 内省回答「需要什么才能做对」
  → CodeAgent 修改配置文件（单次最小化修改）
  → 保存 diff 快照 → 回到循环起点
- 无缺陷 → 进入终止判断

### 3. 终止与产出

- CodeAgent 判断调优已收敛或达到循环上限（默认 5 轮）
- 输出：调优前后配置对比、每轮变更摘要、测试结果对比

## 当前进度

- [ ] 设计方案完成（design.md）
- [ ] SKILL.md 执行规范
- [ ] 引导式内省 prompt 模板
- [ ] 端到端验证

## 已知问题

暂无，首次设计阶段。
