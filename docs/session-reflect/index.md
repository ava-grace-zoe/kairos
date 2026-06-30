# session-reflect

用户级会话反思与跨工具策略维护 skill。它在会话结束或用户要求“反思 / 总结会话 / 更新画像”时运行，把当前会话中的稳定证据沉淀到画像层和候选工作流库，再反推出 Agent 可执行策略。

## 概述

`session-reflect` 维护四类内部文件，并保留一个对外稳定入口：

1. `~/.agents/session-reflect/profile.md`：画像沉淀层，保存跨会话稳定的用户偏好、协作模式、思维模式和风险线索。
2. `~/.agents/session-reflect/context.md`：执行策略源文件，只写“你应该怎么做”。
3. `~/.agents/session-reflect/history.md`：审计日志层，追加记录每次更新的证据、推导和变更摘要。
4. `~/.agents/session-reflect/workflow-candidates.md`：候选工作流库，累计跨会话重复流程，达到阈值后建议沉淀为 skill。
5. `~/.agents/context.md`：对外稳定入口，推荐指向 `session-reflect/context.md`，供各 Agent 常驻读取。

适用场景：

- 会话结束时，用户要求“反思”“总结会话”“更新画像”。
- 用户希望把本次协作中暴露出的稳定偏好同步为长期策略。
- 用户希望 AI 指出本次协作中的思维模式、盲区或重复工作流。

不适用场景：

- 项目任务进度保存；这类信息应交给 `progress-manager`。
- 心理诊断、人格测评或非工程领域分析。
- 把项目私有实现细节写入 Agent 常驻上下文。

## 文件结构

```text
skills/session-reflect/
├── SKILL.md
└── scripts/
    └── setup.sh

docs/session-reflect/
├── index.md
├── design.md
├── discussion.md
├── test-plan.md
└── changelog.md

~/.agents/
├── context.md                         # 对外稳定入口，推荐指向 session-reflect/context.md
└── session-reflect/
    ├── profile.md                     # 画像沉淀，供 session-reflect 更新时参考
    ├── context.md                     # Agent 执行策略源文件
    ├── history.md                     # 人类审计日志，不进入 Agent 常驻上下文
    └── workflow-candidates.md         # 跨会话重复工作流候选
```

`profile.md` 的标准结构：

```markdown
# User Profile

## 协作画像
## 工程偏好
## 思维与决策模式
## 风险线索
## 证据索引
```

`context.md` 的标准结构：

```markdown
# Agent Context

## 沟通策略
## 调查与决策策略
## 执行与验证策略
## 防错策略
## 硬性禁区
```

`workflow-candidates.md` 的核心字段：

```markdown
# Workflow Candidates

## 候选规则
## Candidates

### <workflow-id>
- 状态：candidate | recommended | accepted | rejected | archived
- 出现次数：
- 最近出现：
- 适用范围：global | project-family | project-local
- 输入：
- 输出：
- 证据：
- 推荐动作：
```

写作约定：

- `profile.md` 使用第三人称“使用者”，允许保存画像和推导。
- `context.md` 使用第二人称“你”，只写 Agent 可执行策略。
- `history.md` 记录证据和变更过程，可包含项目名和具体历史事件。
- `workflow-candidates.md` 记录跨会话重复工作流候选，不进入 Agent 常驻上下文。
- 不在 `context.md` 中使用第一人称“我”，也不写“使用者是……”这类画像判断。

## 工作流程

1. **只读分析**：读取当前会话、`profile.md`、`workflow-candidates.md`、`context.md` 和必要历史摘要，提取候选证据，不写文件。
2. **证据分轨**：A 轨提取偏好、协作方式、工程习惯和高频重复工作流；B 轨提取思维模式、风险线索和防护需求。
3. **画像草案**：生成 `profile.md` 拟更新摘要，保留证据和推导。
4. **候选工作流草案**：更新 `workflow-candidates.md`，累计出现次数和状态。
5. **策略草案**：从画像反推 `context.md` 拟更新摘要，只输出 Agent 可执行动作。
6. **确认门禁**：在创建、覆盖、软链接或追加任何文件前，必须先向用户展示修改摘要并获得明确确认。
7. **写回与校验**：确认后写回 `profile.md`、`workflow-candidates.md`、`context.md`、追加 `history.md`，必要时执行初始化脚本，最后校验文件存在且 Markdown 未截断。

## 当前进度

- [x] 双轨模型确定：A 轨负责偏好与工作流，B 轨负责风险线索与防护策略。
- [x] 写回前确认门禁纳入标准流程。
- [x] A7 高频重复工作流识别纳入设计，用于输出工程效能建议。
- [x] `context.md` 人称规范确定：只使用“你”给 Agent 下达策略。
- [x] `workflow-candidates.md` 候选工作流库纳入设计。
- [x] 目录化存储与 workflow 候选库已同步到 `SKILL.md` 与 `setup.sh`。
- [ ] 需要用真实会话重新跑一轮目录化模型端到端验证。

## 已知问题

1. **迁移成本**：现有 `context.md` 中已经混入画像与执行策略，需要迁移到 `session-reflect/profile.md` + `session-reflect/context.md` 双文件。
2. **现有配置合并仍需人工判断**：当 Claude / Codex / Gemini 目录里已有非软链接配置文件时，初始化脚本只提示冲突，不自动合并。
3. **Cursor 暂无稳定分发方案**：Cursor 全局规则存储方式不适合直接软链接复用 Markdown。
4. **B 轨证据需要克制写入**：单次会话中的负面或缺陷类观察容易过拟合，证据不足时只进入 `profile.md` 的初步观察或 `history.md`，不反推出长期策略。
5. **候选工作流需要去重**：不同会话可能用不同名字描述同一流程，需要在更新时归并到同一个 workflow id。
6. **工程效能建议仍是建议**：发现高频重复工作流后只提出固化方向，不自动创建新 skill，除非用户明确授权。
