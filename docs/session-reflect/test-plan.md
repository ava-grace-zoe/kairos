# session-reflect 端到端测试方案

## 测试目标

验证 session-reflect 双轨体系在真实会话中完整链路的正确性，包括冷启动初始化、A 轨偏好证据提取、B 轨认知证据提取、context.md 生成、history.md 追加、元认知反馈输出。

## 测试方法

使用 Claude Code CLI 恢复一个已有的长会话，通过 `-r` 恢复上下文，`-p` 传入 session-reflect 触发指令，观察完整执行链路。

```bash
claude -r <session-id> -p "更新画像"
```

## 前置条件

- 备份已有 context.md 和 history.md：`cp ~/.agents/context.md ~/.agents/context.md.bak`
- 删除 context.md 和 history.md，确保走冷启动路径

## 验证 checklist

| # | 检查项 | 预期 |
|---|--------|------|
| 1 | setup.sh 执行 | 成功创建 `~/.agents/context.md` 和 `~/.agents/history.md` |
| 2 | context.md 结构 | 包含 4 个一级章节（基本信息、综合画像、AI 应对指南、偏好与习惯）和子章节（协作风格、思维模式、行为校准、认知防护、硬性禁区） |
| 3 | 无噪音 | 无评分数字、无元数据、无 HTML 注释、无可观测信号 |
| 4 | 协作风格（A 轨） | 内容有会话证据支撑，无项目私有信息，描述编程风格/问题拆解/表达模式 |
| 5 | 思维模式（B 轨） | 基于行为证据的非评判性描述，覆盖决策模式/认知偏误/知识边界等维度 |
| 6 | 行为校准（A 轨） | 可执行的 AI 行为指令，无分数 |
| 7 | 认知防护（B 轨） | 场景化的防护指令，如"当用户在……时，主动……" |
| 8 | history.md | 追加了新条目，格式正确，含 A 轨证据、B 轨证据、元认知反馈摘要 |
| 9 | A 轨证据质量 | 证据引用具体行为，覆盖 5 类偏好维度（A1-A5） |
| 10 | B 轨证据质量 | 证据引用具体行为，至少覆盖 2 类认知维度（B1-B5），单次不足时标注"初步观察" |
| 11 | 元认知反馈 | 在会话输出中直接呈现给用户，语气非评判性，未写入 context.md |

## 恢复方法

测试完成后恢复备份：

```bash
cp ~/.agents/context.md.bak ~/.agents/context.md
cp ~/.agents/history.md.bak ~/.agents/history.md
```
