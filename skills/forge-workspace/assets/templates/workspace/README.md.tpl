# __WORKSPACE__

由 Forge Workspace（工程铸造技能）创建的全栈工作区。

编程智能体从根目录 [AGENTS.md](AGENTS.md) 开始，读取工程总览、重要规则和执行命令；详细文档由 [docs/index.md](docs/index.md) 导航。

## 启动

前置条件：Node.js（JavaScript 运行时）22.23.2、pnpm（performant npm，包管理器）10.28.0，以及 Docker Compose（本地容器编排工具）或已有 PostgreSQL（关系型数据库）。

在本目录执行：

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

默认前端为 http://127.0.0.1:5173，后端健康检查为 http://127.0.0.1:3000/api/health。生成器已经从 `.env.example` 创建本地 `.env`；数据库端口冲突时同步修改 `.env` 中的连接串与 `POSTGRES_PORT`。

## 工作区

- `apps/web/`：React（前端组件库）页面、React Router（路由库）、Zustand（客户端状态库）及 Tailwind CSS（Cascading Style Sheets，层叠样式表工具框架）。
- `apps/api/`：NestJS（后端框架）接口，通过 Zod（运行时数据校验库）校验请求。
- `packages/contracts/`：共享接口契约，由 tsdown（TypeScript 库构建工具）编译。
- `packages/database/`：Prisma ORM（Object-Relational Mapping，对象关系映射工具）模型、迁移及数据库客户端。
- `docs/`：[工程规范、功能文档、项目导航与操作手册](docs/index.md)。

精确依赖版本统一在 `pnpm-workspace.yaml` 的 `catalog` 字段，首次安装后的锁文件必须提交。`.forge/workspace.json` 固定生成器版本，之后新增子项目不自动跟随最新模板。

## 验收与排障

`pnpm check` 检查代码、构建、类型与单元测试；`pnpm test:browser` 检查真实浏览器内的组件交互；`pnpm test:system` 使用构建产物、真实前后端及本次独立创建的数据库模式做完整链路验证。

出错时按[操作手册](docs/runbooks/local-development.md)处理。生成成功不表示测试已通过；在功能文档里记录实际命令和结果。
