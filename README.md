# Kairos

个人 **Agent Skills** 仓库 —— 一个用于扩展 AI 编程助手能力的工具箱。

## 项目结构

```
skills/              Agent Skills（遵循开放 Agent Skills 规范）
├── agent-facing-design/ 设计和审查面向 Agent 的工具与文档
├── forge-workspace/  创建和扩展带文档、前后端、数据库及测试的完整工程
├── git-commit/       按逻辑拆分并提交代码变更
├── personal-memo/    使用 SQLite 管理个人备忘录，支持分类、关键词和时间检索
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
| [`forge-workspace`](docs/forge-workspace/index.md) | 工程铸造：初始化 pnpm 全栈工作区，新增前端、后端或共享包；当前通过本地路径安装 |
| `git-commit` | 将工作区变更拆分为原子提交，遵循约定式提交规范（Conventional Commits） |
| [`personal-memo`](docs/personal-memo/index.md) | 使用 SQLite 管理个人备忘录，默认存储在 `~/person.memo.db`，支持增删改查、分类和时间检索 |
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

### Forge Workspace 本地使用

模板和生成器一起存放在 `skills/forge-workspace/`，安装时一起复制。pnpm（performant npm，依赖包管理器）负责生成后的工程，Kairos 本身仍使用 Bun。

```bash
# 在 Kairos 根目录安装到 Codex 和 Claude Code
npx skills add ./skills/forge-workspace -g -s forge-workspace -a codex claude-code -y

# 也可直接从源码创建工程；目标目录须为空或不存在
bash skills/forge-workspace/scripts/workspace.sh init --target /tmp/my-product --name my-product

# 新增子项目
bash skills/forge-workspace/scripts/workspace.sh add --workspace /tmp/my-product --type react-app --name admin

# 维护者验证生成器和完整工程
bun install --frozen-lockfile
bun run test:forge
bun run test:forge:smoke
```

完整环境、安装后的入口、启动、版本恢复和失败处理见[操作手册](docs/forge-workspace/runbook.md)，实际运行结果见[验收记录](docs/forge-workspace/validation.md)。当前尚未发布远端版本标签，不能把上述本地可用状态理解为已可远端下载。

### 新增 Skill

在 `skills/` 下创建目录，包含 `SKILL.md` 文件：

```
skills/my-skill/
└── SKILL.md       # YAML frontmatter（name、description、version）+ 指令内容
```

## 许可

私有仓库，保留所有权利。
