# SQLite 命令参考

示例可按任务组合使用。SQLite 是嵌入式关系数据库，`sqlite3` 是其命令行工具；SQL（Structured Query Language，结构化查询语言）用于操作数据。

## 环境与路径

运行需要 `sqlite3` 和系统 Shell（命令解释器）。macOS 通常可使用 `/usr/bin/sqlite3`；也可通过 `command -v sqlite3` 定位。缺失时，已有 Homebrew（系统包管理器）可执行 `brew install sqlite`；Debian / Ubuntu 可执行 `sudo apt-get install sqlite3`。

```bash
memo_sqlite=/usr/bin/sqlite3
memo_db="$HOME/person.memo.db"
"$memo_sqlite" --version
```

用户指定其他数据库时，替换 `memo_db` 为其绝对路径。`memo_skill_dir` 表示本次加载的 `SKILL.md` 所在绝对目录。Homebrew 安装的可执行文件可用 `memo_sqlite="$(brew --prefix sqlite)/bin/sqlite3"` 定位。

需要诊断环境时，可以在内存中运行：

```bash
"$memo_sqlite" -batch -bail -init /dev/null -json :memory: \
  < "$memo_skill_dir/assets/probe.sql"
```

预期包含 `"capability":"ok"`。依赖报错时检查可执行文件路径或安装情况；环境可用后无需反复探测。

## 初始化与查看结构

首次记录且数据库文件不存在时，可用分发的表结构创建。已有数据库直接使用；了解陌生数据库时可以运行 `.schema notes` 和 `PRAGMA user_version;`。

```bash
(
  umask 077
  "$memo_sqlite" -batch -bail -init /dev/null "$memo_db" \
    < "$memo_skill_dir/assets/schema.sql"
)
```

父目录需要存在且可写。初始化失败可能留下空文件，先了解错误和文件状态再处理。查询采用 `-readonly`，文件不存在时会报错而不会新建。

结构版本为 `1`。早期数据库的 `category` 可能带有默认值，仍兼容；写入时提供选定的分类即可。

## 分类与检索

了解已有分类和各分类的记录数：

```bash
"$memo_sqlite" -readonly -json "$memo_db" \
  'SELECT category, count(*) AS count FROM notes GROUP BY category ORDER BY category;'
```

已有分类帮助模型理解当前组织方式，分类名称可以随内容扩展。检索可按需要选字段、组合条件、排序和限制条数。例如查“服务器”分类中包含“香港”的记录：

```bash
"$memo_sqlite" -readonly -json "$memo_db" <<'SQL'
SELECT id, category, title, body, created_at, updated_at
FROM notes
WHERE category = '服务器'
  AND (instr(title, '香港') > 0 OR instr(body, '香港') > 0)
ORDER BY updated_at DESC, id DESC;
SQL
```

`instr()` 区分大小写，按字面匹配中文、`%` 和 `_`。多个词可组合为同时匹配或任一匹配；模型可以选取同义词分别搜索。结果较多时可用 `LIMIT`、`OFFSET` 分批读取。`-json` 返回 JSON（JavaScript Object Notation，结构化文本交换格式）；成功但空输出通常表示没有匹配行，错误输出则要另行处理。

时间筛选示例：查北京时间 2026 年 11 月 5 日创建的记录。换成 `updated_at` 即筛选更新时间：

```sql
SELECT * FROM notes
WHERE created_at >= strftime('%Y-%m-%dT%H:%M:%SZ', '2026-11-05T00:00:00+08:00')
  AND created_at < strftime('%Y-%m-%dT%H:%M:%SZ', '2026-11-06T00:00:00+08:00');
```

根据用户表达选择时间字段和时区；包含起点、不包含终点方便处理相邻日期。正文中的到期日期可通过读取内容理解，当前没有独立字段。

## 写入、修改与删除

下面的多行输入块 `<<'SQL'` 关闭 Shell 对正文的变量和命令展开。SQL 字符串中的单引号写成两个单引号，其他文本保持原样；若正文有独占一行的 `SQL`，换一个不冲突的结束标记。`.parameter set` 本身也有表达式和引号解析，不能直接当成原文安全传递通道。

```bash
"$memo_sqlite" -batch -bail -init /dev/null -json \
  -cmd '.timeout 5000' "$memo_db" <<'SQL'
BEGIN IMMEDIATE;
INSERT INTO notes(category, title, body)
VALUES ('服务器', '香港备用机', 'O''Reilly 的机器
这里可以继续写多行正文');
SELECT * FROM notes WHERE id = last_insert_rowid();
COMMIT;
SQL
```

这是示例内容，实际填写模型结合用户信息选择的分类、标题和正文。`id` 是稳定记录标识。修改、删除可复用同一命令入口，替换事务中的语句：

```sql
UPDATE notes
SET body = '补充后的正文', updated_at = strftime('%Y-%m-%dT%H:%M:%SZ', 'now')
WHERE id = 3;
SELECT changes() AS affected;
SELECT * FROM notes WHERE id = 3;
```

```sql
DELETE FROM notes WHERE id = 3;
SELECT changes() AS affected;
```

条件由实际目标决定；同样可以对用户要求的一组记录执行批量操作。更新时保留未涉及的字段和创建时间。`changes()` 返回影响行数，读回可核对保存结果；以命令成功退出判断提交是否完成。

`-bail` 遇错退出，未提交事务在连接关闭后回滚；`.timeout 5000` 最多等待写锁 5 秒。锁错误可检查其他写进程；路径或结构错误先核对目标数据库。事务保证一组写入的一致性，不提供并发正文自动合并。

## 备份

在选定的备份目录中执行，输出文件名可自行选择。已有同名文件时换一个名称以保留旧备份：

```bash
"$memo_sqlite" -readonly "$memo_db" '.backup person.memo.backup.db'
"$memo_sqlite" -readonly person.memo.backup.db 'PRAGMA integrity_check;'
```

第二条预期输出 `ok`。数据库及备份都保存原始内容，默认没有加密。
