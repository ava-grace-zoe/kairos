# Kairos

个人 **Agent Skills** 和 **MCP Servers** 的 Monorepo —— 一个用于扩展 AI 编程助手能力的工具箱。

## 项目结构

```
skills/              Agent Skills（遵循开放 Agent Skills 规范）
├── save-progress/   保存当前会话的工作进度
├── resume-progress/ 恢复上次会话的工作上下文
└── ...

mcps/                MCP Servers（bun workspace 管理）
└── ...

shared/              MCP Servers 之间的共享工具
```

## 安装 Skills

所有 Skills 遵循 [Agent Skills](https://github.com/vercel-labs/skills) 开放格式，可通过 `skills` CLI 安装。

安装全部 Skills：

```bash
npx skills add ava-grace-zoe/kairos
```

安装单个 Skill：

```bash
npx skills add ava-grace-zoe/kairos/save-progress
```

安装后，Skills 会自动对你的 AI 助手（Claude Code、Cursor、Copilot 等）生效，在相关任务触发时自动激活。

## 可用 Skills

| Skill | 说明 |
|-------|------|
| `save-progress` | 汇总当前会话的工作进度并持久化到项目文档 |
| `resume-progress` | 恢复上次会话的工作上下文，立即继续工作 |

## 开发

需要 [Bun](https://bun.sh)。

```bash
# 安装依赖
bun install

# 开发模式运行所有 MCP Servers
bun run dev

# 构建所有包
bun run build
```

### 新增 Skill

在 `skills/` 下创建目录，包含 `SKILL.md` 文件：

```
skills/my-skill/
└── SKILL.md       # YAML frontmatter（name、description、version）+ 指令内容
```

### 新增 MCP Server

在 `mcps/` 下创建包，bun workspaces 会自动识别：

```
mcps/my-mcp/
├── package.json
├── tsconfig.json
└── src/index.ts
```

## 许可

私有仓库，保留所有权利。
