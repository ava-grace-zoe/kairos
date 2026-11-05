# forge-workspace · 工程铸造

创建并扩展具有统一文档、前后端、共享包、数据库和测试的 pnpm 全栈工作区。

## 概述

技能名称从最初的技术描述名改为 `forge-workspace`。实现包括本地模板、生成器、精确版本分发清单、历史缓存恢复和完整验证脚本。适用于创建新工程及向该工程新增前端、后端、共享包；不自动迁移任意既有工程或部署生产环境。

- [设计与技术选型](design.md)
- [可执行操作手册与排障](runbook.md)
- [实际验收记录](validation.md)
- [讨论与设计修正](discussion.md)

## 文件结构

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

docs/forge-workspace/
├── index.md
├── design.md
├── runbook.md
├── validation.md
└── discussion.md

tests/forge-workspace/generator.test.mjs
scripts/smoke-forge-workspace.sh
scripts/audit-forge-runtime.mjs
```

## 工作流程

1. 从 [runbook.md](runbook.md) 准备运行时、安装技能并校验资源。
2. 输入空目标目录与名称创建工作区；生成器输出代码、根目录 `AGENTS.md` 智能体入口、详细文档、锁文件、初始环境配置和固定版本记录。
3. 在目标目录完成安装、迁移、根检查、浏览器及系统测试；通过后开始业务开发。
4. 新增项目时先读生成工程的 `AGENTS.md` 和对应项目文档，再读取现有版本和基础配置，使用匹配模板生成并更新文档；重新安装和运行检查，确认新项目被发现。
5. 源模板变更后运行生成器测试及完整验收，更新分发清单并重新安装。远端发布由单独流程执行。

## 当前进度

- [x] 完成命名、技术选型与分发设计。
- [x] 实现工作区、前端、后端与共享包模板。
- [x] 实现统一文档管理、迁移与测试规范。
- [x] 将生成工程根目录 `AGENTS.md` 明确为智能体总入口，包含总览、核心规则、导航、常用命令和完成标准。
- [x] 实现创建、新增、冲突保护和精确版本恢复。
- [x] 通过生成器行为测试及首次全链路联调。
- [x] 完成本地技能安装与资源校验，并从最终安装副本重新生成和扩展工程通过检查。
- [x] 完成最终完整验收：新增三种子项目、开发热更新、退出与失败清理。
- [ ] 发布远端版本标签（当前未发布）。

## 已知问题

1. 当前 0.1.0 通过本地技能目录安装；远端发布标签尚未创建。未发布版本只能通过原始技能副本或缓存恢复，不能宣称已能从远端下载。
2. 基础版本目录和 TypeScript 根配置改变后，新增项目要求先处理兼容性；自动迁移不在当前版本内。
3. 默认示例功能不包含业务鉴权。生产同源代理、凭据、部署与数据库备份需按实际项目设计。
4. 完整验收在 macOS 的实际工具链及 PostgreSQL 容器上进行；开发监听使用 `FORGE_WATCH_POLLING=1`，本机原生监听受系统错误限制；生成的持续集成工作流尚未在远端平台运行。
