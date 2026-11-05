---
name: forge-workspace
description: 创建包含文档规范、React 前端、NestJS 后端、共享包、Prisma 数据库和 Vitest 测试的 pnpm 全栈工作区，或在其已有工作区新增前端、后端、共享包。用于初始化工程模板、新建 monorepo、增加子项目；不自动迁移任意既有仓库。
---

# Forge Workspace · 工程铸造

使用随技能分发的脚本与模板完成创建和扩展；按目标项目记录的版本执行，不临时改用其他脚手架拼接。

## 前置条件

- Node.js（JavaScript 运行时）22.23.2 或支持的更高偶数版本；pnpm（performant npm，依赖包管理器）10.28.0。
- 完整联调需要独立的本地 PostgreSQL（关系型数据库）；模板可用 Docker Compose（容器编排工具）启动，也可接入现有独立开发库。
- 首次浏览器测试需要安装 Playwright（浏览器自动化工具）的 Chromium 浏览器。Vitest（测试运行器）统一组织所有测试。
- 历史模板未在本地时，需要 Git（版本控制工具）和对应仓库访问权限。

本技能默认采用 TypeScript、Biome、NestJS、React、Zustand、React Router、Tailwind CSS、Vitest、Prisma、Zod、Vite、tsdown。具体版本与用途见生成项目的 `README.md` 和 `docs/`。

## 确定路径和操作

以本次加载的 `SKILL.md` 所在目录作为 `workspace_skill_dir`；必须使用实际绝对路径，不能假设用户安装到了某个固定目录。脚本入口为 [scripts/workspace.sh](scripts/workspace.sh)，模板位于 `assets/templates/`。

先运行帮助和资源校验：

```bash
bash "$workspace_skill_dir/scripts/workspace.sh" --help
bash "$workspace_skill_dir/scripts/workspace.sh" verify
```

从用户上下文获取目标路径和项目名称；缺少目标路径且无法合理推断时再询问。包名采用小写字母、数字和单连字符，以字母开头，最长 48 位。

## 创建工作区

将用户指定的目标绝对路径赋给 `target_workspace`，名称赋给 `workspace_name`。目录必须为空或不存在：

```bash
bash "$workspace_skill_dir/scripts/workspace.sh" init --target "$target_workspace" --name "$workspace_name"
```

输出包含实际路径及生成项目。默认包含 `apps/web`、`apps/api`、`packages/contracts`、`packages/database`，并生成根目录 `AGENTS.md` 智能体入口、详细文档、根配置、测试和 `.forge/workspace.json`。生成后先读该入口，核对工程总览、重要规则、导航和命令与生成结果一致，再执行验证。

随后在目标工作区依次执行：

```bash
pnpm install
pnpm db:generate
pnpm check
```

生成器已经创建 `.env`。如果需要完整联调，先核对 `.env` 指向独立开发库。使用模板容器时运行 `pnpm db:up`；已有数据库时复用现有连接，不另启重复数据库。再执行：

```bash
pnpm db:migrate
pnpm exec playwright install chromium
pnpm test:browser
pnpm test:system
```

用户要求启动时执行 `pnpm dev`；前端默认地址为 `http://127.0.0.1:5173`，健康接口为 `http://127.0.0.1:3000/api/health`。在保持可追踪的进程会话中启动，交付时说明如何停止。

## 新增子项目

读取目标工作区 `AGENTS.md`、`docs/index.md` 和 `.forge/workspace.json`，确认目标是该技能生成的工作区。选择 `react-app`、`nest-app` 或 `shared-package`，分别表示前端、后端或共享包：

```bash
bash "$workspace_skill_dir/scripts/workspace.sh" add --workspace "$target_workspace" --type react-app --name admin
```

额外依赖已有共享包时添加 `--depends-on utilities,contracts`。后端默认依赖数据库和契约，前端默认依赖契约；数据库包不能添加给前端或通用共享包。

脚本检查名称、基础配置、版本和冲突，分配工作区内未使用的默认端口，更新 `docs/projects/` 与项目登记。新增后在根目录运行 `pnpm install`、`pnpm db:generate`、`pnpm check`，涉及浏览器时运行 `pnpm test:browser`；修改共享服务链路时补跑 `pnpm test:system`。检查新增项目出现在构建和测试结果中。

## 版本与失败恢复

- 模板及脚本从本地安装资源读取；初始化会缓存这一版。新增项目优先使用匹配资源，不匹配时使用记录版本的缓存或对应发布标签。
- `.forge/workspace.json` 必须提交。技能升级不会自动升级已有项目；不要更改其校验值来绕过兼容检查。
- 同名包、非空目标或配置不兼容：根据具体错误处理冲突，不覆盖文件或改用最新版。
- 安装失败：保留生成结果，在目标目录修复网络后重试 `pnpm install`；不要重复初始化。
- 资源校验失败：使用者重新安装准确版本。只有维护技能源码时才运行 `node scripts/seal.mjs` 更新分发清单。
- 未发布版本缓存缺失：从原机器恢复缓存或原始技能副本；不能声称该版本已能远端下载。
- 操作锁存在：读取 `.forge/operation.lock` 中进程标识并检查存活状态，仅在确定进程已结束后清理锁。
- 文件监听报 `EMFILE`、`ENOSPC` 或容器挂载无法触发更新：停止当前开发会话后，在工作区根目录执行 `FORGE_WATCH_POLLING=1 pnpm dev` 使用轮询，再验证源码修改能触发更新。
- 数据库或浏览器不可用：完成可运行的检查，准确报告尚未验证部分；不能把生成成功称为全链路通过。

## 交付

提供目标路径、创建或新增的项目、可运行命令、实际测试结果与未验证事项。更新生成项目的相关文档进度。模板、脚本或版本配置变更后重新校验并安装技能，确认安装副本一致。
