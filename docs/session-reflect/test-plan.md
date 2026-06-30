# session-reflect 测试方案

## 测试目标

验证目录化模型是否成立：`profile.md` 负责画像沉淀，`context.md` 只包含 Agent 可执行策略，`workflow-candidates.md` 累计跨会话重复工作流，`history.md` 记录审计日志；同时验证修改前确认门禁、A/B 双轨提取和 A7 工程效能建议。

## 测试范围

- `skills/session-reflect/SKILL.md`
- `skills/session-reflect/scripts/setup.sh`
- `~/.agents/context.md`
- `~/.agents/session-reflect/profile.md`
- `~/.agents/session-reflect/context.md`
- `~/.agents/session-reflect/history.md`
- `~/.agents/session-reflect/workflow-candidates.md`

## 安全测试环境

优先使用临时 HOME 验证初始化脚本，避免污染真实用户配置：

```bash
tmp_home="$(mktemp -d)"
HOME="$tmp_home" bash skills/session-reflect/scripts/setup.sh
find "$tmp_home/.agents" -maxdepth 3 \( -type f -o -type l \) -print | sort
```

真实会话端到端测试前，先备份：

```bash
backup_dir="$HOME/.agents/session-reflect-backup-$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup_dir"
cp -P ~/.agents/context.md "$backup_dir/root-context.md" 2>/dev/null || true
cp -P ~/.agents/session-reflect/profile.md "$backup_dir/profile.md" 2>/dev/null || true
cp -P ~/.agents/session-reflect/context.md "$backup_dir/context.md" 2>/dev/null || true
cp -P ~/.agents/session-reflect/history.md "$backup_dir/history.md" 2>/dev/null || true
cp -P ~/.agents/session-reflect/workflow-candidates.md "$backup_dir/workflow-candidates.md" 2>/dev/null || true
printf 'backup_dir=%s\n' "$backup_dir"
```

## 验证 checklist

| # | 检查项 | 预期 |
| --- | --- | --- |
| 1 | 初始化模板 | 创建 `~/.agents/session-reflect/` 和四个内部文件，并保留 `~/.agents/context.md` 对外入口 |
| 2 | profile.md 结构 | 包含协作画像、工程偏好、思维与决策模式、风险线索、证据索引 |
| 3 | context.md 结构 | 包含沟通策略、调查与决策策略、执行与验证策略、防错策略、硬性禁区 |
| 4 | 确认门禁 | 写入、创建、软链接或追加文件前，先展示拟修改摘要并等待用户明确确认 |
| 5 | A 轨覆盖 | A1-A6 能更新画像和策略；A7 能识别 2 次及以上重复工作流 |
| 6 | A7 去向 | 高频重复工作流进入 `workflow-candidates.md` 和 `history.md`，不默认写入 `context.md` |
| 7 | workflow 候选阈值 | 单次重复记为 candidate，跨会话 2 次 recommended，3 次强建议 skill 化 |
| 8 | B 轨证据质量 | B1-B5 均基于当前会话可观察行为；证据不足时标注“初步观察” |
| 9 | B 轨分层 | B 轨画像写入 `profile.md`，`context.md` 只写对应防护策略 |
| 10 | context.md 人称 | 全文使用“你”给 Agent 下达策略，不使用“我”，不写画像判断 |
| 11 | context.md 去噪 | 无评分、无 HTML 注释、无历史审计、无项目私有实现细节 |
| 12 | history.md 追加 | 新条目包含时间、会话摘要、A/B 轨证据、profile 变更、workflow 候选变更、context 策略变更、工程效能建议 |
| 13 | 写回校验 | 写回后 Markdown 未截断，四个内部文件和对外入口核心章节顺序稳定 |
| 14 | 失败回退 | 写回失败时保留原始文件，并向用户报告失败原因 |

## 端到端测试方法

使用真实长会话触发：

```bash
claude -r <session-id> -p "更新画像"
```

期望流程：

1. skill 完成只读分析并展示 `profile.md`、`workflow-candidates.md`、`context.md`、`history.md` 草案。
2. 用户确认前不修改任何文件。
3. 用户确认后写回 `profile.md`、`workflow-candidates.md`、`context.md` 并追加 `history.md`。
4. 最终输出包含画像变更、候选工作流变更、策略变更、元认知反馈、工程效能建议和待处理项。

## 恢复方法

```bash
backup_dir="<上一步输出的备份目录>"
[ -e "$backup_dir/root-context.md" ] && cp -P "$backup_dir/root-context.md" ~/.agents/context.md
[ -e "$backup_dir/profile.md" ] && cp -P "$backup_dir/profile.md" ~/.agents/session-reflect/profile.md
[ -e "$backup_dir/context.md" ] && cp -P "$backup_dir/context.md" ~/.agents/session-reflect/context.md
[ -e "$backup_dir/history.md" ] && cp -P "$backup_dir/history.md" ~/.agents/session-reflect/history.md
[ -e "$backup_dir/workflow-candidates.md" ] && cp -P "$backup_dir/workflow-candidates.md" ~/.agents/session-reflect/workflow-candidates.md
```
