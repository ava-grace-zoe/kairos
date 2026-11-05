# forge-workspace 操作手册

Forge Workspace（工程铸造技能）包含模板、生成器与资源清单。以下创建、扩展、安装和验收路径已在 macOS 实测；版本及边界见 [validation.md](validation.md)。

## 前置条件

- Node.js（JavaScript 运行时）22.23.2；其他符合 `engines` 的版本尚未逐一验证。
- pnpm（performant npm，依赖包管理器）10.28.0。
- Git（版本控制工具）用于恢复已发布的历史模板。
- Docker Compose（容器服务编排工具）或独立的 PostgreSQL（关系型数据库）开发库。
- Playwright（浏览器自动化工具）的 Chromium 浏览器，由下面的命令安装。
- 维护 Kairos 需要 Bun（仓库包管理器）；生成的工程使用 pnpm。

在准备执行命令的目录核对环境：

```bash
node --version
pnpm --version
docker compose version
docker info
```

前两项预期为 `v22.23.2` 和 `10.28.0`。若使用 nvm（Node Version Manager，Node.js 版本管理器），可执行 `nvm install 22.23.2 && nvm use 22.23.2`。pnpm 版本不符时执行 `npm install --global pnpm@10.28.0`。切换目录后再核对；目录环境插件可能重新选择 Node.js。Docker 服务未启动时先启动 Docker Desktop，或改用已有独立开发库。

## 从哪里获取模板

源码在 `skills/forge-workspace/assets/templates/`。安装 skill（智能体可执行技能）时，模板、脚本、锁文件与 `bundle.json` 一起复制；运行初始化无需再次下载模板，安装工程依赖仍需要包仓库或本地缓存。

目前 0.1.0 **尚未发布远端标签**，在 Kairos 根目录使用本地源安装：

```bash
npx skills ls -g --json
npx skills add ./skills/forge-workspace -g -s forge-workspace -a codex claude-code -y
```

修改源码后，先完成验证与封装，然后替换已安装副本：

```bash
npx skills remove -g forge-workspace -y
npx skills add ./skills/forge-workspace -g -s forge-workspace -a codex claude-code -y
npx skills ls -g --json
```

`skills` CLI（Command-Line Interface，命令行界面）的安装输出给出实际目录；本次为 `~/.agents/skills/forge-workspace`。智能体必须使用加载到的 `SKILL.md` 所在目录，不能假定所有环境路径相同。以下手动示例采用本次安装位置：

```bash
workspace_skill_dir="$HOME/.agents/skills/forge-workspace"
bash "$workspace_skill_dir/scripts/workspace.sh" --help
bash "$workspace_skill_dir/scripts/workspace.sh" verify
```

校验预期输出版本与摘要；资源缺失时重新安装准确版本，不通过重新计算清单掩盖安装损坏。

## 创建并运行工程

在任意目录执行；目标必须为空或不存在。初始化参数为目标绝对路径与工程名称：

```bash
target_workspace=/tmp/forge-example
bash "$workspace_skill_dir/scripts/workspace.sh" init --target "$target_workspace" --name forge-example
cd "$target_workspace"
pnpm install --frozen-lockfile
pnpm check
pnpm db:up
pnpm db:migrate
pnpm exec playwright install chromium
pnpm test:browser
pnpm test:system
pnpm dev
```

生成结果包含 `apps/web`、`apps/api`、`packages/contracts`、`packages/database`，以及文档、根配置、锁文件、`.env` 和 `.forge/workspace.json`。生成器不隐式安装依赖或启动数据库。

`pnpm check` 自动生成 Prisma ORM（Object-Relational Mapping，对象关系映射工具）客户端，再检查格式、依赖边界、构建、类型和单元测试。`pnpm test:browser` 使用 Vitest（统一测试运行器）检查真实浏览器组件；`pnpm test:system` 验证构建后的前后端和真实数据库。

已有独立开发库时，先修改 `.env` 中 `DATABASE_URL`，跳过 `pnpm db:up`，执行迁移。系统测试默认只接受本地数据库；使用远端独立测试库时显式设置 `FORGE_TEST_DATABASE_URL`。测试创建随机模式，完成或失败后删除该模式并关闭服务。

开发前端为 `http://127.0.0.1:5173`，后端健康接口为 `http://127.0.0.1:3000/api/health`。开发命令包含共享包和应用监听，按 `Ctrl+C` 停止；保留数据库数据的停止命令为 `pnpm db:down`。仅要删除这次工程的本地测试数据时，在其根目录执行 `docker compose down --volumes`。

## 新增子项目

继续使用上文的 `workspace_skill_dir`、`target_workspace`。先新增共享包，再向新前端声明依赖：

```bash
bash "$workspace_skill_dir/scripts/workspace.sh" add --workspace "$target_workspace" --type shared-package --name utilities
bash "$workspace_skill_dir/scripts/workspace.sh" add --workspace "$target_workspace" --type react-app --name admin --depends-on utilities
bash "$workspace_skill_dir/scripts/workspace.sh" add --workspace "$target_workspace" --type nest-app --name worker
cd "$target_workspace"
pnpm install
pnpm check
pnpm test:browser
pnpm test:system
```

类型分别生成通用包、React 前端、NestJS 后端；名称使用小写字母、数字和单连字符，以字母开头，最长 48 位。新增后更新锁文件，因此此时不用冻结安装。输出包括新项目路径、项目登记和 `docs/projects/` 文档；新增应用默认端口为 5174、3001。前端默认通过开发代理访问原有 `api`，需要连接其他后端时修改应用代理配置。

`--depends-on` 接受逗号分隔的现有共享包名称；数据库只允许后端消费。根构建、测试和开发命令自动发现新项目。完成后记录实际验收结果，并提交 `.forge/workspace.json`、锁文件及相关文档。

## 固定版本与恢复

初始化将整套分发资源缓存到 `~/.cache/kairos/forge-workspace/<version>-<digest>/`；可用 `FORGE_CACHE_DIR` 指定其他缓存根目录。项目的 `.forge/workspace.json` 记录精确版本、来源及内容摘要。

新增时依次查找匹配的当前安装副本、匹配缓存、记录的 Git 发布标签；旧脚本与旧模板共同执行。标签内容与记录不一致时拒绝使用，不会回退最新版。未发布版本缺失时只能恢复原始副本或缓存；后续创建远端标签不会自动改变已有项目的未发布记录。

## 失败处理

| 现象 | 处理与复验 |
| --- | --- |
| 目标非空、同名包或文档冲突 | 保留现有内容，选择新目标或新名称，再执行原生成命令；无强制覆盖选项 |
| 安装中断 | 保留生成内容，修复网络后在工程根目录重试原安装命令；不要重新初始化 |
| 数据库端口冲突 | 同时调整 `.env` 中的 `POSTGRES_PORT` 和 `DATABASE_URL` 端口，重启本工程容器再执行迁移 |
| 应用端口冲突 | 用 `lsof -nP -iTCP:3000 -sTCP:LISTEN` 核对占用，调整本工程配置；不终止来源不明的进程 |
| 文件监听报 `EMFILE` / `ENOSPC` 或无更新 | 停止开发会话后执行 `FORGE_WATCH_POLLING=1 pnpm dev`，检查源码变更生效；轮询增加文件检查开销 |
| 浏览器缺失 | 执行 `pnpm exec playwright install chromium` 后重试浏览器测试 |
| 资源摘要不符 | 重新安装准确版本并执行 `verify`；使用者不运行封装命令绕过校验 |
| 历史标签下载失败 | 核对仓库权限、网络、记录的标签；恢复准确缓存后重试；不替换来源或版本字段 |
| 基础配置已改变 | 对比 `pnpm-workspace.yaml`、`tsconfig.base.json` 与原版本；当前没有自动接纳或迁移命令，恢复兼容配置后才能自动新增，不手改摘要绕过 |
| `.forge/operation.lock` 存在 | 读取锁文件中的进程号，用 `ps -p <进程号>` 检查；确认对应生成进程已退出后才删除锁并重试 |

## 维护者验收与发布准备

在 Kairos 根目录执行：

```bash
bun install --frozen-lockfile
node skills/forge-workspace/scripts/seal.mjs
bash skills/forge-workspace/scripts/workspace.sh verify
bun run test:forge
bun run check:skill-boundaries
bun run test:skill-boundaries
bun run test:forge:smoke
```

生成器测试使用隔离临时目录，完整验收使用独立工程、缓存、数据库端口和 Compose 项目，并以轮询模式验证开发监听；成功会清理，失败保留工程排障。加 `bash scripts/smoke-forge-workspace.sh --keep` 可保留成功结果。资源变更后必须重新封装、验证、移除旧安装并重新安装，确认摘要一致。

发布时需要单独确定版本，在 `scripts/seal.mjs` 更新版本、以 `--published` 封装、再次验收，然后将该内容提交并发布清单指定的标签。**这些远端操作本次没有执行**；发布前不得把清单设为已发布后分发给用户。发布后才能使用对应标签安装并验证真正的远端恢复路径。
