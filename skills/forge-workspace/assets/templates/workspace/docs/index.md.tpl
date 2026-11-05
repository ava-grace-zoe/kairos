# 工程文档

## 概述

这里是 __WORKSPACE__ 的详细文档入口。编程智能体首次接手先读根目录 [AGENTS.md](../AGENTS.md) 了解工程总览与重要规则，再根据本页导航阅读相关规范、子项目说明和操作手册。

## 文件结构

```text
docs/
├── index.md
├── standards/engineering.md
├── standards/documentation.md
├── standards/testing.md
├── projects/index.md
├── features/notes/index.md
├── decisions/0001-stack.md
├── runbooks/local-development.md
└── templates/feature.md
```

## 工作流程

1. [工程规范](standards/engineering.md)：依赖边界、前后端、数据与命令。
2. [文档规范](standards/documentation.md)：新文档位置、维护时机与完成条件。
3. [测试规范](standards/testing.md)：测试分层、运行方式与结果要求。
4. [子项目导航](projects/index.md)：具体目录、包名及操作命令。
5. [本地运行与排障](runbooks/local-development.md)：从空环境到运行、验证和关闭服务。
6. [记录功能](features/notes/index.md)：示例完整业务链路与验收要求。
7. [技术决策](decisions/0001-stack.md)：选型及关键取舍。

## 当前进度

- [x] 基础代码、规范、示例功能和测试已经生成。
- [ ] 在当前环境完成安装、迁移、构建及全部测试，并记录结果。

## 已知问题

这是开发起点；鉴权、业务权限与生产运维需依据具体产品另行设计。默认仅监听本机，示例数据库凭据只用于本地开发。
