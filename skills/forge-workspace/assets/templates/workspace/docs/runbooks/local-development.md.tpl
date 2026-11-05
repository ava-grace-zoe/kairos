# 本地运行与排障

## 前置条件与输入

在工作区根目录执行。准备 Node.js（JavaScript 运行时）22.23.2、pnpm（包管理器）10.28.0；使用容器数据库时安装 Docker Compose（容器编排工具）。已有本地 PostgreSQL（关系型数据库）也可用，只需把独立开发库连接写入 `.env` 的 `DATABASE_URL`。

首次生成已经创建 `.env`。若文件丢失：

```bash
cp -n .env.example .env
```

`-n` 保留已有配置；不要把包含凭据的 `.env` 提交到仓库。

## 安装、启动、验证

```bash
pnpm install
pnpm db:generate
pnpm db:up
pnpm db:migrate
pnpm check
pnpm exec playwright install chromium
pnpm test:browser
pnpm test:system
pnpm dev
```

已有数据库时跳过 `pnpm db:up`。预期前端 http://127.0.0.1:5173 可提交记录，刷新后记录仍在；健康接口 http://127.0.0.1:3000/api/health 返回 `status: ok`。新增项目端口写在对应配置和 `.forge/workspace.json` 中。

`pnpm check` 执行数据库客户端生成、Biome（代码检查工具）、全量构建、tsc（TypeScript Compiler，类型检查编译器）与 Vitest（测试运行器）。预期所有命令退出码为 0。

## 常见故障

| 现象 | 检查与恢复 |
| --- | --- |
| Node.js 版本不满足 | 按 `.node-version` 安装匹配版本；不要关闭版本检查 |
| 安装失败 | 检查包仓库与网络，重试 `pnpm install`，无需重新生成工作区 |
| 数据库端口占用 | 修改 `.env` 中 `POSTGRES_PORT` 与 `DATABASE_URL`，然后重新启动容器 |
| 数据库连接或认证失败 | 检查 `docker compose ps` 与 `.env`；确认连接的是独立开发库 |
| 找不到数据库客户端 | 执行 `pnpm db:generate`，再执行 `pnpm build:packages` |
| 浏览器可执行文件缺失 | 执行 `pnpm exec playwright install chromium` |
| 根配置变更后不能新增子项目 | 对照固定版本检查配置兼容性；不要篡改元数据校验值绕过检查 |
| 页面能打开但接口失败 | 检查后端健康接口和 `VITE_API_TARGET`；生产环境需单独配置同源代理 |

## 停止与数据

开发终端按 Ctrl+C 关闭监听进程。执行 `pnpm db:down` 停止容器并保留数据卷。系统测试自动清理本次测试模式；不要对开发数据库执行全库清空来恢复测试。

## 文件监听不可用

原生文件监听报 `EMFILE`、`ENOSPC`，或挂载文件修改没有触发更新时，先停止当前开发会话，再在工作区根目录执行：

```bash
FORGE_WATCH_POLLING=1 pnpm dev
```

此模式为前后端和共享包启用轮询，后端构建产物每 300 毫秒检查一次。代价是持续检查文件产生额外开销；原生监听正常时保持默认命令。确认后端源码修改会改变接口结果，并验证共享包重新构建。
