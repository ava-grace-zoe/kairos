# progress-manager 设计文档

## 设计目标

- 合并 `save` / `resume` 为一个技能，降低维护成本。
- 使用文件系统即可完成持久化，不引入数据库。
- 以文件名承载任务标识与状态，保证快速检索。

## 持久化位置

- 根目录：`docs/progress/`
- 一个 progress 对应一个文件。

## 文件命名规范

```text
<what>__<created_at>__<status>.md
```

字段约束：

1. `what`
- 表示“在做什么”，使用小写英文与 `-`，例如 `resume-skill-redesign`。

2. `created_at`
- 创建时间，格式 `YYYYMMDD-HHMMSS`。
- 创建后固定不变，作为唯一性补充。

3. `status`
- 仅允许：`doing`、`blocked`、`done`。
- 状态变更通过重命名文件实现。

示例：

```text
docs/progress/resume-skill-redesign__20260301-111200__doing.md
```

## progress 文件内容模板

```markdown
# <title>

- what: <what>
- created_at: <YYYYMMDD-HHMMSS>
- status: <doing|blocked|done>
- updated_at: <YYYY-MM-DD HH:mm:ss>

## 目标

<一句话目标>

## 已完成

- ...

## 下一步

- ...

## 阻塞

- 无

## 关键文件

- <path>
```

## save 流程

1. 定位目标 progress（用户指定或由上下文推断）。
2. 若不存在则创建 `...__doing.md`。
3. 写入/更新正文字段。
4. 若状态变化，执行文件重命名。

## resume 流程

1. 扫描 `docs/progress/*.md`。
2. 选择优先级：`doing` > `blocked`；同状态按文件修改时间倒序。
3. 读取目标文件并输出：
- 当前状态
- 下一步 1-3 条
- 风险/阻塞

## 最佳实践（落地约束）

1. 下一步必须是可执行动作（避免“继续推进”这类空泛描述）。
2. 阻塞必须写清依赖对象与解除条件。
3. 每次 save 至少更新 `updated_at` 与 `下一步`，保证恢复时信息新鲜。
