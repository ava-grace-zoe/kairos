# progress-manager

统一处理“记录进度（save）”与“恢复进度（resume）”的工作流 skill。

## 概述

`progress-manager` 将原本分离的 `save-progress` 与 `resume-progress` 合并为一个技能，通过同一套数据结构完成会话收尾与会话恢复。

核心目标：

1. 用最小必要信息完成可恢复交接。
2. 在新会话中快速定位当前任务并给出下一步动作。
3. 保持文档结构稳定、可追溯、可批量管理。

## 文件结构

```text
docs/progress-manager/
├── index.md
├── design.md
└── discussion.md

skills/progress-manager/
└── SKILL.md
```

## 工作流程

1. `save`：读取当前会话成果，写入或更新 `docs/progress/` 中对应 progress 文件。
2. `resume`：按规则选择目标 progress，输出状态摘要与下一步动作。
3. 状态变更：通过重命名文件更新状态后缀（`doing|blocked|done`）。

## 当前进度

- [x] 合并方案确定（两个技能合并为一个）
- [x] 状态模型确定（`doing|blocked|done`）
- [x] 文件名规则确定（包含任务名/创建时间/状态）
- [x] 持久化目录确定（`docs/progress/`）
- [x] SKILL.md 实现
- [ ] 使用样例验证

## 已知问题

1. 同名任务冲突仍依赖 `created_at` 区分，命名不规范会降低可读性。
2. 文件重命名更新状态时，外部链接若硬编码文件名会失效。
3. 当前为 Markdown 存储，暂未提供结构化校验脚本。
