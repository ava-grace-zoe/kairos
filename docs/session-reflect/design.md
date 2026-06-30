# session-reflect 设计文档

## 设计目标

`session-reflect` 维护用户级长期上下文，但不把“用户画像”直接暴露给日常 Agent。它将会话证据沉淀为画像和候选工作流，再从画像反推出 Agent 可执行策略。

核心目标：

1. **画像沉淀**：将跨会话稳定的偏好、协作模式、思维模式和风险线索维护到 `profile.md`。
2. **行为校准**：从 `profile.md` 反推 Agent 应做什么，写入给各工具常驻读取的 `context.md`。
3. **审计可追溯**：每次更新的证据、推导和写回摘要追加到 `history.md`。
4. **效能提炼**：识别跨会话重复工作流，维护到 `workflow-candidates.md`，达到阈值后提示用户考虑固化为新的 skill。

约束：

- `context.md` 只放 Agent 可执行策略，不放心理画像、证据流水或项目私有细节。
- `profile.md` 可以保留画像和推导，但必须基于显性行为证据，不做心理诊断或绝对人格判断。
- `workflow-candidates.md` 只记录候选工作流，不直接影响 Agent 常驻策略。
- `history.md` 记录每次更新的证据和变更原因，不进入 Agent 常驻上下文。
- 写入、创建、软链接或追加任何文件前必须得到用户明确确认。

非目标：

- 不保存项目进度；这由 `progress-manager` 处理。
- 不自动生成新 skill；只在发现高频工作流时给出建议，等待用户授权。
- 不让日常 Agent 直接消费完整用户画像。

## 方案概览

```text
当前会话 + session-reflect 工作区
        |
        v
只读分析
        |
        +--> A 轨：偏好、协作、工程习惯、重复工作流
        |
        +--> B 轨：思维模式、认知盲区、防护线索
        |
        v
更新 profile.md 草案
        |
        +--> 更新 workflow-candidates.md 草案
        |
        v
从 profile.md 反推 context.md 策略草案
        |
        v
用户确认门禁
        |
        v
写回 profile.md + workflow-candidates.md + context.md，追加 history.md
```

## 数据模型

### 目录组织

内部文件统一收纳在 `~/.agents/session-reflect/`，避免用户级配置根目录继续膨胀。对外稳定入口仍保留 `~/.agents/context.md`，供 Claude / Codex / Gemini 等工具软链接或直接读取。

```text
~/.agents/
├── context.md                         # 对外稳定入口，推荐指向 session-reflect/context.md
└── session-reflect/
    ├── profile.md                     # 画像沉淀
    ├── context.md                     # Agent 执行策略源文件
    ├── history.md                     # 审计日志
    └── workflow-candidates.md         # 跨会话重复工作流候选
```

### profile.md

`profile.md` 是画像沉淀层，供 `session-reflect` 更新时读取，不作为普通 Agent 的常驻上下文。它可以包含分析性内容，但必须保持中立、证据化、可修正。

```markdown
# User Profile

## 协作画像

## 工程偏好

## 思维与决策模式

## 风险线索

## 证据索引
```

写作规则：

- 使用第三人称“使用者”。
- 描述可观察行为和稳定模式，不写绝对人格标签。
- 负面或缺陷类观察必须条件化，并指向证据索引。
- 单次证据不足时标注“初步观察”。

### context.md

`context.md` 是执行策略层，给 Claude / Codex / Gemini 等 Agent 常驻读取。它不解释“使用者为什么这样”，只告诉 Agent “你应该怎么做”。

```markdown
# Agent Context

## 沟通策略

## 调查与决策策略

## 执行与验证策略

## 防错策略

## 硬性禁区
```

写作规则：

- 使用第二人称命令式“你”。
- 每条都必须是 Agent 可执行动作。
- 不写“使用者是……”这类画像判断。
- 不写第一人称“我”表达用户偏好。
- 不写历史证据、评分、元数据、项目私有实现细节。

### history.md

`history.md` 是审计日志，记录每次更新的证据、画像变化、策略变化和工程效能建议。它可以包含项目名、历史事件和推导过程，但不进入 Agent 常驻上下文。

### workflow-candidates.md

`workflow-candidates.md` 记录跨会话重复出现、可能值得沉淀为 skill / 脚本 / runbook 的候选工作流。它不是 Agent 常驻上下文，也不直接驱动 `context.md`。

```markdown
# Workflow Candidates

## 候选规则

## Candidates

### <workflow-id>

- 名称：
- 状态：candidate | recommended | accepted | rejected | archived
- 出现次数：
- 最近出现：
- 适用范围：global | project-family | project-local
- 输入：
- 输出：
- 证据：
- 推荐动作：
```

候选规则：

- 单次会话内重复出现：记录为 `candidate`。
- 跨会话出现 2 次：状态可升级为 `recommended`，在会话输出中建议评估是否沉淀。
- 跨会话出现 3 次且输入输出稳定：强建议创建 skill、脚本或 runbook。
- 项目私有流程标为 `project-local`，不推荐创建全局 skill，除非能抽象为跨项目模式。
- 用户拒绝后标为 `rejected`，后续只在出现明显新证据时再提。

## 证据体系

### A 轨：偏好与工作流

| 维度 | 关注点 | 主要去向 |
| --- | --- | --- |
| A1 沟通偏好 | 语言、简洁度、解释粒度、是否先执行后解释 | profile.md + context.md |
| A2 表达模式 | 上下文省略、XY 问题倾向、抽象度偏差 | profile.md + context.md |
| A3 协作偏好 | 是否需要确认、是否偏好直接落地、是否同步文档 | profile.md + context.md |
| A4 工程偏好 | 脚本、测试、格式、验证强度、工程权衡 | profile.md + context.md |
| A5 决策与风险偏好 | 速度优先或稳健优先、容错边界 | profile.md + context.md |
| A6 问题解决工作流 | 自顶向下 / 自底向上、排错方式、架构与实现优先级 | profile.md + context.md |
| A7 高频重复工作流 | 2 次及以上出现、输入输出清晰、可被 skill 化的步骤序列 | workflow-candidates.md + history.md + 会话输出 |

A7 不默认写入 `context.md`。只有当候选工作流已经被抽象成通用 Agent 策略，才允许进入 `context.md`。

### B 轨：画像到防护策略

| 维度 | profile.md 记录 | context.md 反推 |
| --- | --- | --- |
| B1 决策模式 | 使用者在什么场景下快决策或慢决策 | 你在高风险决策前如何补验证 |
| B2 认知偏误 | 哪类判断偏差有重复证据 | 你在对应场景如何给反例或校验 |
| B3 知识边界感知 | 使用者如何暴露未知与求证 | 你如何解释概念、避免羞辱感或过度科普 |
| B4 反馈接受模式 | 使用者如何回应挑战与纠错 | 你如何提出挑战更容易被吸收 |
| B5 注意力盲区 | 哪类信息容易被漏看 | 你在对应任务中必须检查什么 |

B 轨原则：

- `profile.md` 保留推导，`context.md` 只保留行动策略。
- 每条风险线索都必须能反推出至少一条 Agent 防护动作。
- 不能从单次会话推导长期负面结论；证据不足时只写“初步观察”。

## 更新流程

1. 只读加载当前会话、`profile.md`、`workflow-candidates.md`、`context.md` 和必要历史摘要。
2. 提取 A/B 轨证据，先列证据，再给画像或策略结论。
3. 生成 `profile.md` 修改草案：新增、修正或删除画像条目。
4. 生成 `workflow-candidates.md` 修改草案：新增候选、累计出现次数、升级状态或记录用户拒绝。
5. 从 `profile.md` 反推 `context.md` 修改草案：只生成 Agent 可执行策略。
6. 生成 `history.md` 追加草案：记录证据、画像变化、候选工作流变化、策略变化和工程效能建议。
7. 展示草案并等待用户确认；未确认前不得写文件。
8. 确认后写回并校验四个内部文件和对外 `context.md` 入口结构完整。

## 关键取舍

### 1. 画像不再常驻给 Agent

画像是中间分析层，适合 `session-reflect` 更新时读取，不适合所有 Agent 日常读取。日常上下文应是操作手册，而不是用户档案。

### 2. context.md 只写策略

Agent 不需要知道“使用者是什么样的人”，只需要知道“在什么场景下你应该怎么做”。这样能降低诊断感、标签误用和上下文污染。

### 3. profile.md 承担沉淀与反推

`profile.md` 保留跨会话稳定画像，让策略更新有依据；同时它不被普通 Agent 常驻读取，降低过拟合画像对日常交互的干扰。

### 4. history.md 保留证据链

`history.md` 让每次更新可审计、可回滚，也允许保留项目名和具体事件，避免把这些细节污染 `context.md`。

### 5. workflow-candidates.md 独立维护

候选工作流需要跨会话累计和去重，不适合塞进 `profile.md`，也不应进入 `context.md`。独立文件让“是否值得 skill 化”有清晰状态和证据。

## 风险与缓解

| 风险 | 表现 | 缓解 |
| --- | --- | --- |
| 画像过拟合 | 把单次会话误写成稳定特征 | profile.md 标注“初步观察”，context.md 不生成长期策略 |
| 策略失去依据 | context.md 只剩指令，不知道为什么 | history.md 保留证据，profile.md 保留推导 |
| context.md 过载 | Agent 常驻上下文变长且不可执行 | 只保留行动策略，删除画像、证据和项目细节 |
| 画像标签误用 | Agent 根据标签臆测用户 | profile.md 不常驻，context.md 不写标签 |
| 过早 skill 化 | 单次会话内重复就推荐创建 skill | workflow-candidates.md 跨会话累计，达到阈值才推荐 |
| 候选工作流膨胀 | 候选长期不处理、重复或过时 | 使用状态字段，支持 rejected / archived |
| 未确认写回 | 长期记忆被静默修改 | 强制确认门禁，无确认不得写文件 |
