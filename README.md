# Kairos

个人 **Agent Skills** 仓库 —— 一个用于扩展 AI 编程助手能力的工具箱。

## 项目结构

```
skills/              Agent Skills（遵循开放 Agent Skills 规范）
├── agent-facing-design/ 设计和审查面向 Agent 的工具与文档
├── git-commit/       按逻辑拆分并提交代码变更
├── progress-manager/ 保存/恢复会话工作进度
└── test-standards/   测试规范参考文档（非独立 Skill）
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
| `agent-facing-design` | 设计、审查和改进面向 Agent 的工具与文档 |
| `git-commit` | 将工作区变更拆分为原子提交，遵循约定式提交规范（Conventional Commits） |
| `progress-manager` | 保存/恢复会话工作进度，用于"保存进度"或"恢复进度/继续上次工作"场景 |

## 开发

需要 [Bun](https://bun.sh)。

```bash
# 安装全部本地 Skills
bun run link:dev
```

`skills` CLI 从本地路径安装时会复制 Skill 内容，修改 `skills/` 下的源文件不会自动更新已安装副本。每次修改后必须重新安装对应 Skill：

```bash
npx skills remove -g <skill-name> -y
npx skills add ./skills/<skill-name> -g -s <skill-name> -y
npx skills ls -g --json
```

最后一个命令用于验证 Skill 已重新注册；若安装仍使用旧内容，再次执行“移除 → 安装”。

### 新增 Skill

在 `skills/` 下创建目录，包含 `SKILL.md` 文件：

```
skills/my-skill/
└── SKILL.md       # YAML frontmatter（name、description、version）+ 指令内容
```

## 许可

私有仓库，保留所有权利。
