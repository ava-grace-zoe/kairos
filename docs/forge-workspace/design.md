# forge-workspace 设计文档

Forge Workspace（工程铸造）创建完整工程工作区，并持续增加前端、后端与共享包。当前为 0.1.0 本地实现；远端发布标签尚未创建。

## 设计目标

- 使用 pnpm（performant npm，依赖包管理器）工作区组织前后端与共享包。
- 生成可执行代码、统一文档规范、数据库迁移、测试与持续集成配置。
- 同一技能覆盖首次创建与后续扩展；固定模板版本，避免新旧根配置混用。
- 不自动迁移任意既有工程，不部署生产服务，不实现任意技术栈组合生成器。

## 方案概览

### 技术基线

用户明确选择 TypeScript、Biome、NestJS、React、Zustand、React Router、Tailwind CSS、Vitest、Prisma 和 Zod。用户随后基本认可方案并要求跑通，第一版采用先前建议的 Vite、tsdown、PostgreSQL 及标准模块格式。

| 范围 | 固定版本 | 用途 |
| --- | --- | --- |
| Node.js / pnpm | 22.23.2 / 10.28.0 | 执行环境与依赖管理 |
| TypeScript | 6.0.3 | 静态类型与独立类型检查 |
| Biome | 2.5.14 | 代码检查、格式化与导入整理 |
| NestJS | 12.1.0 | 后端应用和依赖注入 |
| SWC（Speedy Web Compiler） | 1.16.2 | 后端代码和测试的装饰器转换 |
| React / React Router / Zustand | 19.3.0 / 8.4.0 / 5.0.15 | 组件、数据路由、客户端状态 |
| Vite / Tailwind CSS（Cascading Style Sheets） | 8.3.1 / 4.3.3 | 前端开发构建、工具类样式 |
| Vitest / Playwright | 5.0.2 / 1.63.0 | 统一测试运行器、浏览器驱动 |
| Prisma ORM（Object-Relational Mapping） | 7.10.0 | 数据模型、迁移与查询 |
| PostgreSQL | 18.3 | 关系型数据库 |
| Zod / tsdown | 4.6.5 / 0.23.0 | 运行时接口校验、共享包构建 |

全部直接依赖统一在模板 `pnpm-workspace.yaml` 的 `catalog` 字段；随模板附带已验证锁文件，初次生成可以直接冻结安装。增加子项目后重新安装更新锁文件。Kairos 自身仍使用 Bun（仓库脚本运行工具与包管理器）。

### 维护与分发

资源源位置为 `skills/forge-workspace/`，维护文档在 `docs/forge-workspace/`。技能只引用自身资源，不依赖仓库文档。

```text
skills/forge-workspace/
├── SKILL.md
├── bundle.json
├── scripts/
│   ├── workspace.sh
│   ├── workspace.mjs
│   └── seal.mjs
└── assets/templates/
    ├── workspace/
    ├── react-app/
    ├── nest-app/
    └── shared-package/
```

模板全部以 `.tpl` 结尾，隐藏路径编码为 `__dot__`；生成时恢复真实文件名。这让技能安装工具能携带依赖清单、隐藏配置和工作流文件。安装后用完整资源清单校验，不能只检查 `SKILL.md` 是否存在。

安装时获取技能、脚本、模板和锁文件；初始化读本地资源。初始化同时把此版本放入 `~/.cache/kairos/forge-workspace/<version>-<digest>/`，可用 `FORGE_CACHE_DIR` 指定其他缓存根目录。

目标工作区的 `.forge/workspace.json` 记录名称、项目表、基础配置校验值、分发版本、来源及摘要，必须提交到版本控制。新增项目按“匹配的当前技能 → 匹配缓存 → 精确发布标签”选择整套脚本和模板。旧版本缺失且尚未发布时明确失败，不回退最新版。

分发摘要采用 SHA-256（Secure Hash Algorithm 256-bit，256 位安全散列算法）。`bundle.json` 记录每个资源的路径与摘要，再对版本、来源和资源清单的固定序列化结果计算总摘要；清单文件自身不参与递归计算。历史下载核对总摘要和每个文件，标签内容被改写时拒绝使用。

### 生成结果与运行流程

默认包含 `apps/web`、`apps/api`、`packages/contracts`、`packages/database`。根目录统一提供安装、构建、类型检查、依赖边界检查、单元、浏览器组件和系统测试。`docs/` 包含规范、项目导航、功能文档、技术决策、操作手册和功能文档模板。

生成工程根目录的 `AGENTS.md` 是编程智能体直接读取的总入口，覆盖工程定位、目录职责、技术基线、接手顺序、关键约束、常用命令与完成标准。`docs/index.md` 提供详细文档导航，专题规范和排障流程按任务加载。相较将全部规范复制进根文件，这样可以保留关键约束的可见性，同时减少重复维护；改变工程结构、根命令或全局规则时必须同步更新根入口。新增子项目的具体名称和端口由项目导航与版本登记维护，根入口通过导航发现新增项目。

前端通过数据路由加载和提交记录，Zustand 管理筛选状态；后端通过 Zod 校验输入并调用 Prisma。共享契约与持久化模型分离，浏览器不能导入数据库或后端实现。根命令检查依赖图、跨包相对引用和浏览器侧服务端模块导入。

`pnpm dev` 先生成数据库客户端并完成构建，再启动包监听与应用监听。共享包监听使用 `--no-clean` 保留产物，避免与应用启动发生竞态；后端只监听本工程构建目录。原生文件监听不可用时，可用 `FORGE_WATCH_POLLING=1 pnpm dev` 将各监听器切换到轮询，代价是周期性文件检查开销。应用端口写入项目登记与配置，新增时避开工作区中已登记的端口；操作系统上被其他进程占用的端口由启动器报错，不擅自终止其他服务。

## 关键取舍

### 通用包使用 tsdown，数据库包逐文件编译

仅用 tsc（TypeScript Compiler，TypeScript 编译器）能够编译内部包；tsdown 方便统一入口、声明产物和依赖外置，因此用作通用共享包默认构建器。Prisma 生成代码保持模块结构，用 tsc 逐文件编译。所有包都独立执行 `tsc --noEmit`，不以打包成功替代类型检查。

tsup（另一款 TypeScript 库构建器）的[官方仓库](https://github.com/egoist/tsup)已声明不再积极维护，未选为新模板默认值。tsdown 的[声明生成](https://tsdown.dev/options/dts)与[依赖处理](https://tsdown.dev/options/dependencies)提供选型依据。实测 TypeScript 7.0.2 能构建，但 tsdown 提示编译接口支持仍属实验性，因此固定为 6.0.3；不是基于未经验证的性能判断。

### NestJS 构建与测试共享装饰器配置

采用 SWC 直接编译后端，Vitest 使用 `unplugin-swc` 转换，并验证 NestJS 测试模块中的构造器注入。相较引入 NestJS 命令行生成器，直接使用 SWC 更符合此处已有模板、独立 pnpm 包及显式配置的需求；该取舍不改变后端框架。[NestJS 官方配置依据](https://docs.nestjs.com/recipes/swc)

Biome 显式开启参数装饰器解析，避免把 NestJS 的合法参数装饰器判为语法错误。

### 统一运行器，区分测试对象

单元和后端模块使用 Vitest 服务端环境；组件使用 Vitest 浏览器模式与 Playwright 驱动；系统测试仍由 Vitest 组织，通过 Playwright 控制真实浏览器访问构建产物。系统启动器先创建随机隔离数据库模式并迁移，再启动前后端，结束后关闭进程和清理模式。

测试默认使用本地独立开发库；远端测试必须显式提供独立的 `FORGE_TEST_DATABASE_URL`。组件通过不能代替数据库与部署入口通过。相关官方依据：[Vitest 浏览器模式](https://vitest.dev/guide/browser/)、[Playwright 控制库](https://playwright.dev/docs/library)。

### 模板与技能共同分发

独立模板仓库适合多工具复用，独立生成器包适合无智能体的命令行产品；两者都会增加发布与兼容关系。当前入口是 Kairos 技能，因此先共同分发。资源不依赖全局安装路径，shell（命令解释器）只做环境和入口处理，结构化写入由无第三方运行时依赖的 Node.js 脚本完成。

### 基础配置变化需要显式兼容审查

新增项目会保留已有代码和人工文档说明。为了避免默默生成不匹配项目，基础版本目录或 TypeScript 根配置变化后暂不自动扩展；也不提供强制跳过校验参数。自动迁移与配置接纳属于后续版本范围。普通业务代码与应用配置变化不触发这一限制。

## 数据与接口

在 Kairos 根目录执行；完整环境准备及恢复步骤见 [runbook.md](runbook.md)。

```bash
bash skills/forge-workspace/scripts/workspace.sh --help
bash skills/forge-workspace/scripts/workspace.sh verify
bash skills/forge-workspace/scripts/workspace.sh init --target /tmp/my-product --name my-product
bash skills/forge-workspace/scripts/workspace.sh add --workspace /tmp/my-product --type react-app --name admin
```

`init` 输入空目录或新目录与名称，输出工作区、文档、初始 `.env` 和版本记录。`add` 输入已生成的工作区、类型与名称，可选 `--depends-on utilities,contracts`，输出新项目、文档和更新后的登记。两者只生成文件，依赖安装与服务启动由后续命令执行。

成功退出码为 0，错误为 1；输出包含绝对路径、具体错误和后续命令。新增操作使用 `.forge/operation.lock` 防止并发写入；同名目录、同名包、路径越界或符号链接写入在修改前拒绝。失败恢复不会覆盖已有内容。

## 风险与缓解

| 风险 | 影响 | 约束与验证 |
| --- | --- | --- |
| 新旧模板混用 | 子项目无法消费根配置 | 固定分发版本与摘要，旧脚本配旧模板 |
| 安装过滤资源 | 缺少隐藏配置和依赖清单 | `.tpl` 编码与安装后逐文件校验 |
| 根配置改变 | 新模板约定失效 | 比对基础配置，发现变化明确报错 |
| 构建和测试转换不同 | 后端注入失效 | 构造器注入测试加构建后真实请求 |
| 浏览器带入数据库实现 | 运行失败或暴露服务端逻辑 | 显式包边界及根命令检查 |
| 测试资源残留 | 进程占用或数据污染 | 独立模式、成功失败清理、服务进程组回收 |
| 终端切换运行时 | 安装版本与预期不同 | 在目标目录核对 `node --version` 与 `pnpm exec node --version` |

验证事实和未验证边界统一记录在 [validation.md](validation.md)，不把生成成功或官方文档支持当作整套模板已实测的证明。
