# Kairos

个人 **Agent Skills** 仓库 —— 一个用于扩展 AI 编程助手能力的工具箱。

## 项目结构

```
skills/              Agent Skills（遵循开放 Agent Skills 规范）
├── progress-manager/ 保存/恢复会话工作进度
├── session-reflect/  会话反思、策略维护与候选工作流沉淀
└── ...
```

## 安装 Skills

所有 Skills 遵循 [Agent Skills](https://github.com/vercel-labs/skills) 开放格式，可通过 `skills` CLI 安装。

安装全部 Skills：

```bash
npx skills add ava-grace-zoe/kairos
```

安装单个 Skill：

```bash
npx skills add ava-grace-zoe/kairos --skill progress-manager
```

安装后，Skills 会自动对你的 AI 助手（Claude Code、Cursor、Copilot 等）生效，在相关任务触发时自动激活。

## 可用 Skills

| Skill | 说明 |
|-------|------|
| `progress-manager` | 保存/恢复会话工作进度，用于"保存进度"或"恢复进度/继续上次工作"场景 |
| `session-reflect` | 会话结束时沉淀画像、维护 Agent 执行策略，并累计候选工作流 |

## 开发

需要 [Bun](https://bun.sh)。

```bash
# 本地软链全部 Skills，便于调试
bun run link:dev
```

### 新增 Skill

在 `skills/` 下创建目录，包含 `SKILL.md` 文件：

```
skills/my-skill/
└── SKILL.md       # YAML frontmatter（name、description、version）+ 指令内容
```

## 许可

私有仓库，保留所有权利。
