# Kairos

Personal monorepo for Agent Skills and MCP Servers.

## Structure

- `skills/` — Agent Skills（每个子目录包含 SKILL.md，遵循 Agent Skills 规范）
- `mcps/` — MCP Servers（bun workspace packages）
- `shared/` — MCP 间的共享工具
- `docs/` — 项目文档（每个 skill/功能一个同名目录，使用 `index.md` 作为入口）

## Conventions

- Package manager: bun
- MCP servers use TypeScript
- Skills 遵循 open Agent Skills 规范（SKILL.md with YAML frontmatter）
- 所有文档和注释使用简体中文

## Skill 目录规范

```
skills/<skill-name>/
├── SKILL.md              # Skill 定义（必须）
├── scripts/              # 可执行脚本（可选）
└── assets/               # 模板、静态资源（可选）
```

## 文档规范

- 文档统一放在 `docs/` 目录下
- 每个 skill 对应一个同名目录：`docs/<skill-name>/`
- `index.md` 为必选入口文档，用于总览与导航
- 可选扩展文档（按需创建）：
  - `design.md`：设计方案与关键取舍
  - `discussion.md`：讨论记录与待决策事项
  - `changelog.md`：变更记录（对外可见行为变化）
  - `runbook.md`：操作手册与排障步骤
- 模板目录：`docs/template/skill-docs/`
- 模板入口：[docs/template/skill-docs/index.md](docs/template/skill-docs/index.md)
- 使用时机：
  - 新建 skill 文档目录时，直接基于模板初始化
  - 旧文档从单文件迁移到目录结构时，按模板补齐缺失文档
  - 文档缺少标准章节（概述/文件结构/工作流程/当前进度/已知问题）时，用模板对齐结构
  - 新成员接手或跨人协作时，用模板统一文档组织与写作粒度
- 推荐目录模板：
  ```text
  docs/<skill-name>/
  ├── index.md        # 总览与导航（必选）
  ├── design.md       # 设计方案（可选）
  ├── discussion.md   # 讨论与决策过程（可选）
  ├── changelog.md    # 变更记录（可选）
  └── runbook.md      # 操作与排障（可选）
  ```
- 文档应包含以下章节：
  - 概述 — 这个 skill 是什么、解决什么问题
  - 文件结构 — 目录树
  - 工作流程 — 核心执行步骤
  - 当前进度 — checklist 形式
  - 已知问题 — 待解决的问题和边界情况

## Skill 制作流程规范

Skill 的制作遵循 **design → docs → skill** 三阶段路径，每个阶段有明确的产出和完成标准。

### 总览

```text
阶段 1: design          阶段 2: docs           阶段 3: skill
docs/<name>/design.md → docs/<name>/index.md → skills/<name>/SKILL.md
                         docs/<name>/其他文档
```

核心原则：

- **先想清楚再写**：design 阶段收敛目标和方案，避免在 SKILL.md 中边写边改
- **文档即设计评审**：docs 阶段将设计具象化，暴露 design 中遗漏的细节
- **SKILL.md 是执行合约**：只包含 AI 执行所需的指令，设计推导过程留在 docs

### 阶段 1：Design

目的：收敛目标、探索方案、记录取舍。

- 产出：`docs/<skill-name>/design.md`
- 内容要求（参照 `docs/template/skill-docs/design.md` 模板）：
  - 设计目标 — 要做什么、不做什么
  - 方案概览 — 架构 / 流程简述、关键模块、依赖与约束
  - 关键取舍 — 方案对比与决策理由
  - 数据与接口 — 输入 / 输出 / 中间状态
  - 风险与缓解
- **启发式引导**：AI 在协助设计时，应通过提问帮助用户收敛思路，而非直接给出方案。根据设计进展按需选用，不必全部走完：
  - 目标澄清：
    - 如果这个 skill 做成了，用户的哪个具体痛点会消失？
    - 你能描述一个「没有这个 skill 时的典型失败场景」吗？
    - 这个 skill 和 `<已有相关 skill>` 的边界在哪？谁不该做什么？
    - 有哪些看起来相关但你明确不想做的事？（非目标）
  - 方案探索：
    - 最简单的能 work 的版本长什么样？去掉哪些东西它依然有用？
    - 如果这个 skill 的所有数据都丢了，重建的成本有多大？这暗示了什么？
    - 你设想的执行步骤中，哪一步最可能出错？出错后怎么办？
    - 这个方案有没有隐含假设？（比如：假设 X 已经存在 / 假设用户会提供 Y）
  - 边界与约束：
    - 这个 skill 的触发条件是什么？有没有不该触发但可能误触发的场景？
    - 它需要读写哪些外部状态？（文件、API、环境变量）有什么并发或冲突风险？
    - 最大处理规模是什么量级？（条目数 / 文件大小 / 调用频次）
  - 风险前瞻：
    - 如果这个 skill 被误用了，最坏情况是什么？有什么防护措施？
    - 半年后你回来看这个设计，最可能困惑的是哪部分？
    - 哪些决策是现在必须定的，哪些可以推迟到实际使用后再决定？
- 完成标准：
  - [ ] 目标和非目标清晰可判定
  - [ ] 至少有一个关键取舍经过方案对比
  - [ ] 依赖和约束已列出
- 可选产出：`docs/<skill-name>/discussion.md`（讨论记录、探索过程、被否决的想法）

### 阶段 2：Docs

目的：将设计落实为结构化文档，覆盖执行所需的全部细节。

- 产出：`docs/<skill-name>/index.md`（必选）+ 扩展文档（按需）
- 内容要求（参照 `docs/template/skill-docs/index.md` 模板）：
  - 概述 — 一句话定义 + 适用 / 不适用场景
  - 文件结构 — 目录树
  - 工作流程 — 核心执行步骤（输入 → 处理 → 输出）
  - 当前进度 — checklist 形式
  - 已知问题 — 待解决的问题和边界情况
- 完成标准：
  - [ ] index.md 五个标准章节齐全
  - [ ] 工作流程可直接翻译为 SKILL.md 的执行步骤
  - [ ] 文件结构与实际目录树一致
- 回流机制：docs 编写过程中发现 design 遗漏 → 更新 design.md，在 discussion.md 记录原因

### 阶段 3：Skill

目的：产出 AI 可直接执行的 SKILL.md。

- 产出：`skills/<skill-name>/SKILL.md`（必选）+ `scripts/`、`assets/`（按需）
- 内容要求：
  - YAML frontmatter（`name` + `description`，description 包含触发关键词）
  - 前置条件
  - 执行步骤 — 从 docs 的工作流程转化而来，面向 AI 的指令式表达
  - 辅助资源引用（如有）
- 完成标准：
  - [ ] YAML frontmatter 格式正确
  - [ ] 执行步骤覆盖 docs 中定义的工作流程
  - [ ] 引用的辅助资源文件实际存在
  - [ ] SKILL.md 中指向 design.md 的链接，示例：`设计文档：docs/<skill-name>/design.md`
- 禁止事项：
  - 不在 SKILL.md 中重复设计推导过程（留在 design.md）
  - 不在 SKILL.md 中放置讨论和决策记录（留在 discussion.md）

### 阶段间关系

| 从 → 到       | 依赖关系                                      | 回流触发条件                      |
| ------------- | --------------------------------------------- | --------------------------------- |
| design → docs | docs 的工作流程基于 design 的方案概览展开     | docs 发现方案不可行或遗漏关键细节 |
| docs → skill  | SKILL.md 的执行步骤从 docs 的工作流程转化     | SKILL.md 执行中发现流程缺失       |
| skill → docs  | SKILL.md 变更后同步更新 docs 的工作流程和进度 | 实际执行偏离文档描述              |

### 快速参考

| 阶段   | 产出路径                 | 模板                                 | 核心问题          |
| ------ | ------------------------ | ------------------------------------ | ----------------- |
| design | `docs/<name>/design.md`  | `docs/template/skill-docs/design.md` | 为什么这么做？    |
| docs   | `docs/<name>/index.md`   | `docs/template/skill-docs/index.md`  | 具体怎么做？      |
| skill  | `skills/<name>/SKILL.md` | —                                    | AI 执行什么指令？ |

## 用户偏好

- 使用简体中文沟通和编写文档
- 不要废话，不需要确认就直接执行
- 文件不存在就直接创建，不要停下来提示
- 遵循规范前先确认实际规范内容，不要凭猜测编写
- 偏好 shell 脚本处理初始化和环境配置
