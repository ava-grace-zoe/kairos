# session-reflect 端到端测试方案

## 测试目标

验证 session-reflect 在真实会话中完整链路的正确性，包括冷启动初始化、5 类证据提取、context.md 生成、history.md 追加。

## 测试方法

使用 Claude Code CLI 恢复一个已有的长会话，通过 `-r` 恢复上下文，`-p` 传入 session-reflect 触发指令，观察完整执行链路。

```bash
claude -r 6e81982a-ea01-445b-9a13-a0fcc2c28a15 -p "更新画像"
```

## 前置条件

- 备份已有 context.md 和 history.md：`cp ~/.agents/context.md ~/.agents/context.md.bak`
- 删除 context.md 和 history.md，确保走冷启动路径

## 验证 checklist

| # | 检查项 | 预期 |
|---|--------|------|
| 1 | setup.sh 执行 | 成功创建 `~/.agents/context.md` 和 `~/.agents/history.md` |
| 2 | context.md 结构 | 只有 4 个章节：基本信息、综合画像、AI 应对指南、偏好与习惯 |
| 3 | 无噪音 | 无评分数字、无元数据、无 HTML 注释、无可观测信号 |
| 4 | AI 应对指南 | 只有行为描述，无分数 |
| 5 | 综合画像 | 新增内容有会话证据支撑，无项目私有信息 |
| 6 | history.md | 追加了新条目，格式正确，含关键证据和变更记录 |
| 7 | 证据质量 | 证据引用具体行为，覆盖 5 类证据维度 |

## 恢复方法

测试完成后恢复备份：

```bash
cp ~/.agents/context.md.bak ~/.agents/context.md
cp ~/.agents/history.md.bak ~/.agents/history.md
```
