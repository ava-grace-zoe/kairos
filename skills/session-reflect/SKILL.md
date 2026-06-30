---
name: session-reflect
description: 在会话结束或用户要求"反思/总结会话/更新画像/session reflect"时，基于当前会话证据更新用户画像、候选工作流、Agent 执行策略和审计历史。写入任何长期记忆文件前必须先向用户确认修改草案。
---

# session-reflect 执行规范

目标：维护用户级长期记忆，但把“画像沉淀”和“Agent 常驻策略”分开。`profile.md` 保存画像与推导，`workflow-candidates.md` 保存跨会话重复工作流候选，`context.md` 只保存 Agent 可执行策略，`history.md` 记录审计历史。

设计文档：`docs/session-reflect/design.md`

不做项目进度保存、心理诊断、人格测评，也不自动创建新 skill。

## 强制确认门禁

在执行任何修改前，必须先向用户展示拟修改摘要并获得明确确认。

需要确认的修改包括：

- 运行 `skills/session-reflect/scripts/setup.sh`
- 创建 `~/.agents/session-reflect/` 或其中任何文件
- 创建、覆盖或改变 `~/.agents/context.md`
- 覆盖写回 `profile.md`、`workflow-candidates.md` 或 `context.md`
- 追加写入 `history.md`
- 创建或改变任何指向 `~/.agents/context.md` 或 `~/.agents/session-reflect/context.md` 的软链接

未获得明确确认前，只能执行只读分析和输出草案，不得写入文件。

## 一、路径与初始化检查

使用以下路径：

```text
~/.agents/
├── context.md                         # 对外稳定入口，推荐指向 session-reflect/context.md
└── session-reflect/
    ├── profile.md                     # 画像沉淀
    ├── context.md                     # Agent 执行策略源文件
    ├── history.md                     # 审计日志
    └── workflow-candidates.md         # 跨会话重复工作流候选
```

执行步骤：

1. 只读检查上述路径是否存在，不存在时只生成初始化计划。
2. 若 `~/.agents/context.md` 已存在且不是指向 `session-reflect/context.md` 的软链接，不要覆盖；将其视为待迁移旧入口，并在草案中说明人工迁移方案。
3. 若内部文件缺失，先进入“强制确认门禁”；确认后才可执行 `skills/session-reflect/scripts/setup.sh`。
4. 检查核心章节是否齐全；缺失章节时只列为拟补齐项，等待确认后再写回，不删除已有内容。

`profile.md` 标准结构：

```markdown
# User Profile

## 协作画像

## 工程偏好

## 思维与决策模式

## 风险线索

## 证据索引
```

`context.md` 标准结构：

```markdown
# Agent Context

## 沟通策略

## 调查与决策策略

## 执行与验证策略

## 防错策略

## 硬性禁区
```

`workflow-candidates.md` 标准结构：

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

## 二、会话分析

只分析当前会话中用户的显性行为、决策、反馈和表达方式。项目配置文件中的约束不等于用户级稳定偏好，除非用户在会话中明确认可。

### 2.1 A 轨：偏好与工作流

提取前先列事实证据，再给结论。只保留跨项目可复用的信息。

- A1 沟通偏好：语言、简洁度、解释粒度、是否偏好先执行后解释。
- A2 表达模式：上下文省略、XY 问题倾向、环境/版本/日志遗漏类型、抽象度偏差。
- A3 协作偏好：是否需要确认、是否偏好直接落地、是否要求同步文档。
- A4 工程偏好：脚本/工具、测试、格式、验证强度、工程权衡立场。
- A5 决策与风险偏好：速度优先或稳健优先、可接受的验证强度、容错边界。
- A6 问题解决工作流：自顶向下或自底向上、报错时要修复还是排查思路、架构与实现优先级。
- A7 高频重复工作流：当前会话出现 2 次及以上、输入输出清晰、可被 skill / 脚本 / runbook 固化的半手动步骤序列。

A1-A6 可更新 `profile.md`，并反推出 `context.md` 策略。A7 进入 `workflow-candidates.md`、`history.md` 和会话输出，不默认写入 `context.md`。

### 2.2 A7 候选工作流规则

更新 `workflow-candidates.md` 时遵循：

1. 先和已有候选按输入、输出、步骤和适用范围去重；同一流程不要创建多个 id。
2. 当前会话内重复出现只说明“可候选”，跨会话阈值按不同会话计数；同一会话最多计 1 次。
3. 单次会话内重复出现，记录或保持 `candidate`。
4. 跨会话出现 2 次，状态可升级为 `recommended`，并在输出中建议评估是否沉淀。
5. 跨会话出现 3 次且输入输出稳定，强建议创建 skill、脚本或 runbook。
6. 项目私有流程标为 `project-local`，不推荐全局 skill，除非能抽象成跨项目模式。
7. 用户拒绝后标为 `rejected`；后续只在出现明显新证据时再提。

### 2.3 B 轨：画像到防护策略

基于可观察行为提取五类证据：

- B1 决策模式：快速决策与深思熟虑的切换时机，是否存在该慢却快的场景。
- B2 认知偏误：锚定效应、确认偏误、沉没成本、可得性偏差等反复出现的判断偏差。
- B3 知识边界感知：不熟悉领域中的自信度、保守度、求证方式。
- B4 反馈接受模式：对纠正、挑战、反例的响应方式，是否区分“不喜欢”和“不正确”。
- B5 注意力盲区：反复忽略的边界条件、时区、错误处理、性能、安全等信息。

B 轨分层规则：

- `profile.md` 保留画像、推导和风险线索。
- `context.md` 只保留从画像反推出的 Agent 防护动作。
- 不能从单次会话推导长期负面结论；证据不足时只在 `profile.md` 标注“初步观察”，不生成长期策略。
- 每条进入 `profile.md` 的风险线索都必须能反推出至少一条 Agent 防护动作。

## 三、草案生成规则

`profile.md` 写作规则：

- 使用第三人称“使用者”。
- 描述可观察行为和稳定模式，不写绝对人格标签。
- 负面或缺陷类观察必须条件化，并指向证据索引。
- 单次证据不足时标注“初步观察”。

`context.md` 写作规则：

- 使用第二人称命令式“你”。
- 每条都必须是 Agent 可执行动作。
- 不写“使用者是……”这类画像判断。
- 不使用第一人称“我”表达用户偏好。
- 不写历史证据、评分、元数据、项目私有实现细节。

禁止写入 `context.md`：

- 用户画像、心理画像、性格标签。
- 项目私有目标、模块实现细节、临时 workaround。
- 单次任务指令。
- 候选工作流的完整步骤。
- 评分、元数据、HTML 注释、历史审计信息。
- 第一人称用户偏好描述，如“我喜欢……”“我希望……”。

## 四、确认与写回

确认前必须向用户展示：

1. 初始化或软链接动作，包含准确路径。
2. `profile.md` 将新增、修改、删除的画像和证据。
3. `workflow-candidates.md` 将新增、合并、升级、拒绝或归档的候选。
4. `context.md` 将新增、修改、删除的 Agent 策略。
5. `history.md` 将追加的摘要。
6. B 轨中任何负面或缺陷类观察。
7. A7 工程效能建议。

等待用户明确确认。没有确认时停止在草案阶段。

确认后写回：

1. 必要时执行 `skills/session-reflect/scripts/setup.sh`。
2. 写回前备份即将修改的文件内容。
3. 覆盖写回 `~/.agents/session-reflect/profile.md`。
4. 覆盖写回 `~/.agents/session-reflect/workflow-candidates.md`。
5. 覆盖写回 `~/.agents/session-reflect/context.md`。
6. 追加写入 `~/.agents/session-reflect/history.md`。
7. 写回失败时恢复写回前内容并报告失败原因。

写回校验：

- 四个内部文件存在且是有效 Markdown。
- `profile.md`、`context.md`、`workflow-candidates.md` 核心章节齐全且未截断。
- `history.md` 存在本次新增版本号。
- `~/.agents/context.md` 不存在、冲突或指向异常时，明确报告，不静默覆盖。

`history.md` 追加格式：

```markdown
### vYYYYMMDD-HHMMSS
- 时间：YYYY-MM-DD HH:MM:SS
- 会话摘要：（一句话）
- A 轨证据：（偏好与工作流证据）
- B 轨证据：（思维模式与风险线索，含初步观察标记）
- profile.md 变更：（画像与证据索引变更摘要）
- workflow-candidates.md 变更：（候选工作流变更摘要）
- context.md 变更：（Agent 策略变更摘要）
- 元认知反馈：（本次输出给用户的认知洞察摘要）
- 工程效能建议：（如无则写“无”）
```

## 输出要求

确认前输出草案：

1. 证据摘要
2. `profile.md` 拟修改内容
3. `workflow-candidates.md` 拟修改内容
4. `context.md` 拟修改内容
5. `history.md` 拟追加内容
6. 需要用户确认的问题

确认并写回后输出结果：

1. 初始化或写回是否成功
2. 本次版本号
3. profile 画像变更
4. workflow 候选变更
5. context 策略变更
6. B 轨元认知反馈
7. 工程效能建议
8. 待用户处理项
