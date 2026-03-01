# session-reflect

用户级会话反思与画像维护 Skill。

## 概述

在会话结束或用户明确要求反思时，自动完成三件事：

1. 初始化并校验 `~/.agents/context.md`
2. 基于用户行为证据执行维度评分与画像更新
3. 将变更历史追加到独立的 `~/.agents/history.md`

`~/.agents/context.md` 通过软链接分发到多个编程助手工具，作为跨工具共享的用户级配置事实源。该 Skill 默认排除项目私有实现细节，仅沉淀跨项目稳定偏好。

扩展文档：
- 设计文档：`design.md`
- 讨论记录：`discussion.md`
- 测试方案：`test-plan.md`

## 文件结构

```text
skills/session-reflect/
├── SKILL.md
└── scripts/
    └── setup.sh

docs/session-reflect/
├── index.md
├── design.md
└── discussion.md

~/.agents/
├── context.md          # 用户画像（AI 消费，软链接分发）
└── history.md          # 变更历史（人类审计，不进入 AI 上下文）
```

## 工作流程

1. 初始化阶段：读取 `~/.agents/context.md`，不存在则执行 `scripts/setup.sh`。校验核心章节是否齐全，缺失则按 SKILL.md 内联结构补齐。
2. 会话分析阶段：提取用户级证据；按 3 个维度（自主性期望、上下文投入度、工程审美基线）评分；评分为内部过程，不写入 context.md，只驱动 AI 应对指南生成。
3. 写回阶段：覆盖写回 `context.md`（只含基本信息、综合画像、AI 应对指南、偏好与习惯），追加写入 `history.md`（含评分详情）。

## 当前进度

- [x] SKILL.md 三阶段规范
- [x] 画像抽取目标收敛为"用户级稳定偏好"
- [x] setup.sh 初始化脚本（创建文件 + 软链接）
- [x] 维度体系设计（3 评分维度 + 定性描述）
- [x] 变更历史独立文件（history.md）
- [x] context.md 去噪（移除评分、元数据、可观测信号，只保留 AI 可消费内容）
- [x] template.md 删除（初始结构内联到 SKILL.md + setup.sh）
- [x] SKILL.md 适配最终方案
- [ ] 实际会话中的端到端测试

## 已知问题

1. 软链接与已有配置冲突：`setup.sh` 当前策略是跳过并警告，仍需用户手动合并。
2. Cursor 暂无方案：Cursor 全局规则存储在 SQLite，无法直接复用软链接分发策略。
3. 用户级/项目级边界依赖执行质量：需执行时严格遵守排除项，避免写入项目私有内容。
4. 版本回滚未脚本化：尚未在 `scripts/` 中提供自动回滚工具。
