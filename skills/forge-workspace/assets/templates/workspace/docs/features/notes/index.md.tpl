# 记录功能

## 概述

一个最小完整业务链路：前端提交标题，后端校验并持久化，刷新页面后仍可读取。它用于验证工程连接，也可作为新功能的参考。

## 文件结构

- `packages/contracts/src/index.ts`：输入输出契约。
- `packages/database/prisma/schema.prisma`：持久化模型。
- `apps/api/src/notes.*.ts`：接口、业务和模块测试。
- `apps/web/src/app.tsx`、`notes-list.tsx`：路由、提交与展示。
- `tests/system/workspace.test.ts`：真实数据库和浏览器验收。

## 工作流程

页面加载 `GET /api/notes`，提交 `POST /api/notes`，输入为 `{ "title": "我的第一条记录" }`。标题去除首尾空格后必须为 1–120 字符，额外字段被拒绝；有效提交返回记录标识、标题和字符串形式的创建时间。

验收条件：有效记录可保存且刷新后存在；空标题和超长标题返回失败；筛选只改变当前视图；无效输入不能进入数据库。命令见根目录 `pnpm check`、`pnpm test:browser`、`pnpm test:system`。

## 当前进度

- [x] 生成契约、模型、接口、页面与行为测试。
- [ ] 在当前环境执行全部验证并填写实际结果。

## 已知问题

示例只提供新增与最近 100 条记录查询，未包含鉴权、删除或分页。添加真实业务需求时先补充契约和验收标准。
