---
name: git-commit
description: 对当前工作区的变更进行原子化的多次 git commit，遵循 Conventional Commits 规范。
---

对当前工作区的变更进行原子化的多次 git commit，遵循 Conventional Commits 规范。

## 核心原则

- **原子性**：每个 commit 只包含一个逻辑变更，可独立理解、独立 revert
- **自洽性**：每个 commit 后项目应保持可编译/可运行状态
- **可追溯性**：commit message 应准确描述变更意图，而非罗列文件

## Commit Message 规范

遵循 Conventional Commits 规范，格式如下：

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

核心规则：

- `type` 和 `subject` 是必需的，`scope`、`body`、`footer` 可选
- `scope` 用括号包裹，标识变更影响的模块，如 `feat(auth):`
- `subject` 使用中文，简洁描述变更意图，不加句号
- `footer` 中可用 `BREAKING CHANGE: <描述>` 补充说明

### Type 类型

| Type       | 用途                   |
| ---------- | ---------------------- |
| `feat`     | 新功能                 |
| `fix`      | 修复缺陷               |
| `refactor` | 重构（不改变外部行为） |
| `docs`     | 文档变更               |
| `test`     | 测试相关               |
| `chore`    | 构建/工具/依赖等杂项   |
| `style`    | 代码格式（不影响逻辑） |
| `perf`     | 性能优化               |
| `ci`       | CI/CD 配置             |

### 示例

```
feat(auth): 新增 JWT token 自动刷新逻辑
refactor(brain): 提取 stream handler 为独立 pipeline
docs(protocol): 更新消息格式规范说明
fix(chat): 修复重连时消息重复发送的问题
chore: 升级 ai-sdk 至 v6.1.0
```

## 执行步骤

1. **分析变更** — 运行 `git status` 和 `git diff`（含 staged 和 unstaged），全面了解当前工作区的所有变更。

2. **分类归组** — 将变更按逻辑单元分组，每组对应一个原子 commit。分组依据：
   - 同一功能的新增/修改归为一组
   - 重构类变更单独一组
   - 文档变更单独一组
   - 测试变更单独一组（除非与功能紧密耦合）
   - 配置/依赖变更单独一组
   - 纯格式调整单独一组

3. **确认计划** — 向用户展示拟定的 commit 计划：

   ```
   拟定 commit 计划（共 N 个）:

   1. feat(auth): 新增 JWT 刷新逻辑
      - src/auth/token.ts
      - src/auth/refresh.ts

   2. refactor(brain): 重构 stream handler
      - src/brain/pipeline.ts

   3. docs: 更新协议文档
      - docs/protocol.md
   ```

   等待用户确认或调整后再执行。

4. **逐个提交** — 按计划依次执行：

   ```bash
   git add <files>
   git commit -m "<type>(<scope>): <subject>"
   ```

   - 每次 commit 前确保只 stage 该组的文件
   - 如果某个文件包含多个逻辑变更，使用 `git add -p` 进行部分暂存
   - 每次 commit 后运行 `git status` 确认状态正确

5. **输出总结**：

   ```
   ✅ 已完成 N 个原子 commit:

   <hash1> feat(auth): 新增 JWT 刷新逻辑
   <hash2> refactor(brain): 重构 stream handler
   <hash3> docs(protocol): 更新消息格式规范

   当前分支: main (ahead 3)
   ```

## 注意事项

- commit message 的 `type` 和 `scope` 保持英文，`subject` 使用中文
- 如果用户通过 $ARGUMENTS 指定了额外说明（如 scope、描述），优先参考
- 不要把不相关的变更混入同一个 commit
- 如果变更量很小（只有 1-2 个文件且属同一逻辑），直接合并为一个 commit 即可，不必过度拆分
- 如果存在未保存的文件或冲突，先提醒用户处理
- 绝不自动 push，提交完成后让用户自行决定是否 push
