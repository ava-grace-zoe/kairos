# __WORKSPACE__ · 智能体工作入口

本文件面向首次进入工程的 Agent（编程智能体），适用于整个工作区。修改某个目录前，同时读取该路径上存在的下级 `AGENTS.md`，了解局部补充约定。

## 工程总览

这是使用 TypeScript（静态类型语言）和 pnpm（performant npm，包管理器）组织的全栈多项目工作区。初始示例贯通记录的创建、查询、数据库持久化和浏览器交互；具体业务范围以 [功能文档](docs/features/notes/index.md) 为准。

| 位置 | 职责与技术 |
| --- | --- |
| `apps/web/` | 默认前端：React 组件、React Router 数据路由、Zustand 客户端状态、Tailwind CSS（Cascading Style Sheets，层叠样式表工具框架）；Vite 提供开发与构建 |
| `apps/api/` | 默认后端：NestJS 框架提供接口与业务服务 |
| `packages/contracts/` | 前后端共享输入输出契约，使用 Zod 做运行时结构校验 |
| `packages/database/` | PostgreSQL 关系型数据库、Prisma ORM（Object-Relational Mapping，对象关系映射工具）的模型、迁移与客户端 |
| `apps/`、`packages/` | 后续应用与共享包的位置；完整名单和操作说明见 [子项目导航](docs/projects/index.md) |
| `docs/` | 工程规范、项目说明、功能、技术决策与操作手册，入口为 [docs/index.md](docs/index.md) |
| `.forge/workspace.json` | 模板来源、固定版本、项目登记与默认端口 |

## 开始任务

1. 在工作区根目录运行 `git status --short` 查看现有改动；Git 是版本控制工具，已有改动必须保留。尚未初始化版本控制时，先按实际文件状态工作。
2. 阅读 [文档入口](docs/index.md)，从 [子项目导航](docs/projects/index.md) 找到本次修改范围，再阅读对应功能文档和已有代码。
3. 按任务补读专题规范：[工程与依赖边界](docs/standards/engineering.md)、[文档管理](docs/standards/documentation.md)、[测试分层](docs/standards/testing.md)。安装、启动或排障时读 [本地运行手册](docs/runbooks/local-development.md)。
4. 新功能先写 `docs/features/<name>/index.md` 的目标、输入输出和可观察的验收条件，再实现代码。文档创建步骤见文档管理规范。

## 重要规则

- 文档和注释使用简体中文；首次出现缩写展开全称并解释用途。操作步骤写清执行目录、输入、命令、预期输出与失败处理。
- 使用 pnpm 10.28.0，Node.js（JavaScript 运行时）版本以 `.node-version` 为准。公共依赖版本在 `pnpm-workspace.yaml` 的 `catalog` 字段维护，内部依赖使用 `workspace:*`；每个包显式声明自己的依赖，提交 `pnpm-lock.yaml`。
- 应用只通过共享包的公开入口引用代码，不使用跨包源码相对路径；应用之间不直接依赖。浏览器代码不得导入数据库包、后端实现或运行时凭据。
- React Router 负责路由数据的加载、提交和错误状态；Zustand 管理客户端共享交互状态，避免重复保存同一份路由数据。
- 输入输出契约维护在 `packages/contracts/`，数据库模型维护在 `packages/database/`；后端校验输入并明确映射输出，不把数据库记录直接作为公开契约。
- 通用共享包由 tsdown（TypeScript 库构建工具）构建；类型检查单独执行。Biome 统一负责代码检查与格式化，Vitest 统一组织单元、浏览器和系统测试。
- 数据库迁移先在独立开发库验证，提交迁移文件，已应用的迁移不得改写。`.env`、生成代码 `packages/database/src/generated/` 和构建产物不提交；数据库客户端通过命令生成，不手工编辑。
- 新增子项目使用 forge-workspace（工程创建与扩展技能），按 `.forge/workspace.json` 固定版本生成并更新项目导航。技能不可用时先核对来源与安装方式；不绕过版本校验或覆盖修改过的根配置。
- 对外行为、配置或操作步骤变化时，同步更新相关文档；跨项目技术取舍记录在 `docs/decisions/`。工程结构、根命令或全局约定改变时，同时更新本文件。

## 常用命令

以下命令都在工作区根目录执行。首次生成已创建 `.env`，启动前核对 `DATABASE_URL` 指向独立开发库；环境准备、连接配置和预期响应见本地运行手册。

| 场景 | 命令与结果 |
| --- | --- |
| 首次安装 | `pnpm install --frozen-lockfile`，按已有锁文件安装；新增包或修改依赖后用 `pnpm install` 更新锁文件 |
| 准备本地数据库 | `pnpm db:up` 启动 Docker Compose（容器编排工具）服务，`pnpm db:migrate` 应用迁移；使用已有独立开发库时跳过启动容器 |
| 启动开发 | `pnpm dev`，先生成客户端和构建，再启动应用及共享包监听；默认前端 `http://127.0.0.1:5173`，后端健康接口 `http://127.0.0.1:3000/api/health` |
| 基础检查 | `pnpm check`，验证数据库客户端生成、代码规范、依赖边界、构建、类型与单元测试 |
| 浏览器交互改动 | `pnpm test:browser`；首次运行前执行 `pnpm exec playwright install chromium`，Playwright 提供浏览器驱动 |
| 前后端或数据库链路改动 | `pnpm test:system`，使用构建产物及真实数据库；自动创建并清理本次隔离模式和服务进程 |
| 停止服务 | 开发终端按 `Ctrl+C`；`pnpm db:down` 停止数据库容器并保留数据 |

安装失败时保留工程，在根目录修复网络后重试安装，不重复初始化。文件监听报 `EMFILE`、`ENOSPC` 或没有触发更新时，先停止开发会话，再运行 `FORGE_WATCH_POLLING=1 pnpm dev`。其他失败按本地运行手册排查，保留错误与复现输入。

## 完成与交付

- 按改动范围完成上述检查，记录实际运行日期、命令、结果和未验证事项。测试覆盖可观察行为；生成成功或构建成功不能代替运行验收。
- 更新相关功能文档的进度与已知问题，核对文档中的路径、链接、命令和实际代码；文档检查目前需要人工或智能体执行，`pnpm check` 不校验文档内容。
- 交付时说明改动、影响和验证结论，明确区分“已实测”“从代码推断”“尚未验证”。
