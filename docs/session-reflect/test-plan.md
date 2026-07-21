# session-reflect 测试方案

## 测试目标

验证目录化模型是否成立：`profile.md` 负责画像沉淀，`context.md` 只包含 Agent 可执行策略，`workflow-candidates.md` 累计跨会话重复工作流，`history.md` 记录实际发生的变更；同时验证默认 no-op、修改前确认门禁、A/B 双轨提取和 A7 工程效能建议。

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
| 8 | B 轨证据质量 | B1-B5 均基于可观察行为；证据不足的候选不写入长期文件 |
| 9 | B 轨分层 | B 轨画像写入 `profile.md`，`context.md` 只写对应防护策略 |
| 10 | context.md 人称 | 全文使用“你”给 Agent 下达策略，不使用“我”，不写画像判断 |
| 11 | context.md 去噪 | 无评分、无 HTML 注释、无历史审计、无项目私有实现细节 |
| 12 | history.md 追加 | 新条目包含时间、会话摘要、A/B 轨证据、profile 变更、workflow 候选变更、context 策略变更、工程效能建议 |
| 13 | 写回校验 | 写回后 Markdown 未截断，四个内部文件和对外入口核心章节顺序稳定 |
| 14 | 失败回退 | 写回失败时保留原始文件，并向用户报告失败原因 |
| 15 | 运行时资源边界 | `SKILL.md` 不引用仓库级 `docs/`，所有运行时引用都随 Skill 安装包分发 |
| 16 | no-op | 当前会话只有已存在偏好或项目事实时，不生成修改草案、不请求确认、不写 history |
| 17 | 稳定性门槛 | 单次行为推断和单次负面观察不进入长期画像或策略 |
| 18 | 范围路由 | Issue、分支、Tag、模块等项目细节默认过滤；只有稳定重复工作流可进入 project-local candidate |
| 19 | 语义去重 | 与已有条目同义的候选被判为 duplicate，不新增近义 bullet |
| 20 | 变更预算 | 单次草案不超过 profile 3 条、workflow 2 条、context 3 条 |
| 21 | 汇报顺序 | 确认前和写回后都先给总结论或拟变更，再列分项内容，最后列支撑证据 |

运行资源边界检查：

```bash
bun run test:skill-boundaries
```

预期输出：

```text
[ok] skill runtime boundary tests
```

## 语义回归用例

| 用例 | 输入特征 | 预期 |
| --- | --- | --- |
| duplicate-only | 会话再次表现出已有的中文简洁沟通偏好 | no-op，不写任何文件 |
| project-delivery | 会话包含 Issue、MR、Release、Tag 和 Pipeline 状态核对 | 项目细节不进入 profile/context；若流程重复且输入输出稳定，最多进入 project-local candidate |
| explicit-correction | 用户明确说“不要把设计文档放进运行时 Skill” | 可作为跨项目工程偏好候选，但必须先与现有 Agent-facing 内容规范去重 |
| single-negative | 单次会话中用户遗漏一个边界条件 | 不写负面画像，不生成长期防护策略 |
| repeated-workflow | 同一会话重复执行相同步骤多次 | 当前会话对 candidate 计数最多 +1，不得伪造多个跨会话证据 |
| oversized-draft | 同时发现十个候选变化 | 只保留预算内的高优先级变化，其余标为 deferred |
| report-order | 同时有 profile 和 context 拟变更，且证据较多 | 首段先总结拟改内容，分项中先写变更再写证据，不以证据摘要开场 |

## 端到端测试方法

使用真实长会话触发：

```bash
claude -r <session-id> -p "更新画像"
```

期望流程：

1. skill 先完成只读分析、证据门槛、范围路由和语义去重。
2. 无合格增量时输出 no-op 和过滤原因，不请求确认，不修改任何文件。
3. 有合格增量时只展示发生变化的精简 diff；用户确认前不修改任何文件。
4. 用户确认后只写回有变化的长期文件，并在 `history.md` 追加一条变更摘要。
5. 最终输出明确区分已写入变更、被过滤候选和待处理项。

## 恢复方法

```bash
backup_dir="<上一步输出的备份目录>"
[ -e "$backup_dir/root-context.md" ] && cp -P "$backup_dir/root-context.md" ~/.agents/context.md
[ -e "$backup_dir/profile.md" ] && cp -P "$backup_dir/profile.md" ~/.agents/session-reflect/profile.md
[ -e "$backup_dir/context.md" ] && cp -P "$backup_dir/context.md" ~/.agents/session-reflect/context.md
[ -e "$backup_dir/history.md" ] && cp -P "$backup_dir/history.md" ~/.agents/session-reflect/history.md
[ -e "$backup_dir/workflow-candidates.md" ] && cp -P "$backup_dir/workflow-candidates.md" ~/.agents/session-reflect/workflow-candidates.md
```
