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
- 证据不足时只列为本次被过滤候选，不写入长期文件。

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
- 不能从单次会话推导长期负面结论；证据不足时不写入长期文件。

## 更新流程

1. 只读加载当前反思窗口、`profile.md`、`workflow-candidates.md`、`context.md` 和必要历史摘要。
2. 明确反思窗口；同一线程包含多个独立任务时，不默认把整条线程当成同一份证据。
3. 提取 A/B 轨事实证据，按证据门槛判定为稳定、候选或不采纳。
4. 将候选结论与现有条目分类为 `duplicate`、`refine`、`replace`、`remove` 或 `new`；`duplicate` 不产生变更。
5. 先执行 no-op 判定。没有合格增量时直接报告“不更新”，不请求确认，也不写任何文件。
6. 有增量时生成受变更预算限制的 `profile.md`、`workflow-candidates.md` 和 `context.md` 草案。
7. 生成 `history.md` 追加摘要，只记录本次真正发生的变更。
8. 按总—分结构展示精简 diff：先总结打算新增、修改或删除什么，再分项列出变更内容，最后附支撑证据。
9. 等待用户确认；未确认前不得写文件。
10. 确认后写回并校验四个内部文件和对外 `context.md` 入口结构完整。

## 证据门槛与范围路由

### 稳定性门槛

- 用户明确表述的跨项目偏好或纠正，可在单次会话进入 `profile.md` 候选，但仍需通过去重和范围检查。
- 仅从行为推断出的正向偏好，默认需要至少两个不同历史版本的独立证据；单次证据只进入本次分析，不写长期画像。
- 负面、缺陷或风险类结论，必须有至少两个不同历史版本的独立证据，或由用户明确自述；否则最多进入本次会话反馈，不写 `profile.md` 和 `context.md`。
- `context.md` 只能由已达到稳定门槛的画像反推出通用行动策略，不能因为本次任务出现一个具体问题就新增常驻规则。

### 范围路由

- 包含项目名、Issue / MR 编号、分支、Tag、文件路径、模块名、内部标签或临时命令的内容，默认过滤，不因这些事实单独追加 `history.md`。
- 项目内确实反复出现、输入输出稳定的工作流，可进入 `project-local` workflow candidate。
- 只有去掉项目专有名词后仍能独立成立的行为模式，才有资格进入 `profile.md` 或 `context.md`。
- 项目配置文件中的规则不等于用户偏好；只有用户在交互中明确认可时才能作为画像证据。

### 去重与变更预算

- 每条候选必须说明它与已有条目的关系。无法指出实质差异时，按 `duplicate` 处理。
- 优先修正错误或过时条目，其次精炼已有条目，最后才新增条目。
- 单次写回最多修改 3 条 profile、2 条 workflow candidate、3 条 context 策略；超出部分只列为 deferred，不写入。
- `history.md` 记录变更摘要，不复述整场会话。

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

### 6. 设计文档不进入运行时 Skill

`docs/session-reflect/` 面向 Skill 设计者和维护者，记录设计取舍、测试方案和演进历史；它不随独立 Skill 安装包分发，也不是 Agent 执行反思所需的上下文。

`skills/session-reflect/SKILL.md` 必须自包含核心执行合约，只能引用同一 Skill 目录内随包分发的 `scripts/`、`references/` 或 `assets/`。设计追溯由 `docs/session-reflect/index.md` 负责，不能从运行时 `SKILL.md` 反向依赖仓库级文档。

### 7. 默认 no-op，而不是默认沉淀

长期记忆的质量取决于克制。反思的默认结果应是“不需要更新”；只有证据跨过稳定性、范围和去重三道门槛后才生成写回草案。这样可以减少重复画像、项目细节污染和确认疲劳。

### 8. 用户汇报遵循金字塔原理

证据驱动是内部判定顺序，不是用户汇报顺序。对用户输出时，必须先给结论和拟变更，再给分项内容，最后给证据。不得让用户读完证据后自己推断 Skill 想改什么。

## 风险与缓解

| 风险 | 表现 | 缓解 |
| --- | --- | --- |
| 画像过拟合 | 把单次会话误写成稳定特征 | 证据不足的候选只在当次输出中说明过滤原因，不写长期文件 |
| 策略失去依据 | context.md 只剩指令，不知道为什么 | history.md 保留证据，profile.md 保留推导 |
| context.md 过载 | Agent 常驻上下文变长且不可执行 | 只保留行动策略，删除画像、证据和项目细节 |
| 画像标签误用 | Agent 根据标签臆测用户 | profile.md 不常驻，context.md 不写标签 |
| 过早 skill 化 | 单次会话内重复就推荐创建 skill | workflow-candidates.md 跨会话累计，达到阈值才推荐 |
| 候选工作流膨胀 | 候选长期不处理、重复或过时 | 使用状态字段，支持 rejected / archived |
| 未确认写回 | 长期记忆被静默修改 | 强制确认门禁，无确认不得写文件 |
| 运行时引用失效 | 独立安装 Skill 后找不到仓库级设计文档 | SKILL.md 不引用 `docs/`，仅引用包内运行时资源 |
| 机械追加画像 | 每次反思都硬凑新条目 | 先做语义去重和 no-op 判定，没有增量就不写 |
| 单次任务过拟合 | 把项目操作推导成长期偏好 | 使用稳定性门槛和范围路由，项目事实默认过滤 |
| 草案过长 | 用户无法判断真正变化 | 设置变更预算，只展示变化 diff，未变文件一行说明 |
| 证据先于结论 | 用户读了很多上下文仍不知道将改什么 | 按“总结论 → 分项变更 → 支撑证据”汇报 |
