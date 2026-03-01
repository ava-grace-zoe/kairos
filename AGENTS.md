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

## 用户偏好

- 使用简体中文沟通和编写文档
- 不要废话，不需要确认就直接执行
- 文件不存在就直接创建，不要停下来提示
- 遵循规范前先确认实际规范内容，不要凭猜测编写
- 偏好 shell 脚本处理初始化和环境配置
