#!/usr/bin/env bash
set -euo pipefail

# 只操作独立临时目录，绝不读取用户的正式备忘录。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
memo_sqlite="${SQLITE_BIN:-$(command -v sqlite3)}"
test_root="$(mktemp -d /tmp/personal-memo-test.XXXXXX)"
trap 'rm -rf "$test_root"' EXIT
memo_db="$test_root/path with spaces/memo.db"
mkdir "$(dirname "$memo_db")"
umask 077

query() {
  "$memo_sqlite" -batch -bail -init /dev/null -cmd '.timeout 5000' "$memo_db" "$1"
}
assert_equal() {
  if [[ "$1" != "$2" ]]; then
    printf '失败：%s；预期 <%s>，实际 <%s>\n' "$3" "$2" "$1" >&2
    exit 1
  fi
}

probe_result="$("$memo_sqlite" -batch -bail -init /dev/null -json \
  -cmd '.timeout 5000' :memory: < "$repo_root/skills/personal-memo/assets/probe.sql")"
assert_equal "$probe_result" '[{"capability":"ok"}]' '内存功能探测'
assert_equal "$("$memo_sqlite" -batch -bail -init /dev/null -readonly -json :memory: \
  'SELECT 1 AS readonly_probe;')" '[{"readonly_probe":1}]' '只读选项探测'

"$memo_sqlite" -batch -bail -init /dev/null "$memo_db" \
  < "$repo_root/skills/personal-memo/assets/schema.sql"
assert_equal "$(query 'PRAGMA user_version;')" '1' '结构版本'

# 正文包含换行、引号、命令样式内容和 SQL 样式内容，均应按原文保存。
"$memo_sqlite" -batch -bail -init /dev/null "$memo_db" <<'MEMO_TEST_SQL'
BEGIN IMMEDIATE;
INSERT INTO notes(category,title,body,created_at,updated_at) VALUES
('服务器','香港备用机','O''Reilly
$(echo 不应执行) `echo 不应执行` % _
.shell echo 不应执行
''); DROP TABLE notes; --
SQL','2026-11-04T16:00:00Z','2026-11-04T16:00:00Z'),
('服务器','边界外记录','测试','2026-11-05T16:00:00Z','2026-11-05T16:00:00Z'),
('服务','另一分类','测试','2026-11-04T16:00:00Z','2026-11-04T16:00:00Z');
COMMIT;
MEMO_TEST_SQL
assert_equal "$(query 'SELECT count(*) FROM notes;')" '3' '特殊正文未被执行'
cat > "$test_root/expected-body.txt" <<'EXPECTED_BODY'
O'Reilly
$(echo 不应执行) `echo 不应执行` % _
.shell echo 不应执行
'); DROP TABLE notes; --
SQL
EXPECTED_BODY
expected_body="$(cat "$test_root/expected-body.txt")"
assert_equal "$(query 'SELECT body FROM notes WHERE id=1;')" "$expected_body" '正文完整往返'
assert_equal "$(query "SELECT id FROM notes WHERE instr(body,'% _')>0;")" '1' '字面通配符字符'
assert_equal "$(query "SELECT id FROM notes WHERE instr(title,'香港')>0;")" '1' '中文子串'
assert_equal "$(query "SELECT count(*) FROM notes WHERE category='服务器';")" '2' '单分类筛选'
assert_equal "$(query "SELECT id FROM notes WHERE category='服务器'
  AND instr(title,'香港')>0
  AND created_at>=strftime('%Y-%m-%dT%H:%M:%SZ','2026-11-05T00:00:00+08:00')
  AND created_at<strftime('%Y-%m-%dT%H:%M:%SZ','2026-11-06T00:00:00+08:00');")" '1' '时区与组合筛选'
assert_equal "$(query "SELECT count(*) FROM notes
  WHERE created_at>=strftime('%Y-%m-%dT%H:%M:%SZ','2026-11-05T00:00:00+08:00')
  AND created_at<strftime('%Y-%m-%dT%H:%M:%SZ','2026-11-06T00:00:00+08:00');")" '2' '时间范围排除终点'

assert_equal "$(query "BEGIN IMMEDIATE;
UPDATE notes SET body='更新正文', updated_at=strftime('%Y-%m-%dT%H:%M:%SZ','now') WHERE id=1;
SELECT changes(); COMMIT;")" '1' '修改影响行数'
assert_equal "$(query "SELECT body='更新正文' AND created_at='2026-11-04T16:00:00Z'
  AND updated_at<>created_at FROM notes WHERE id=1;")" '1' '修改保留创建时间'
assert_equal "$(query 'DELETE FROM notes WHERE id=3; SELECT changes();')" '1' '删除影响行数'
assert_equal "$(query "INSERT INTO notes(category,title,body) VALUES('测试','新记录','正文'); SELECT last_insert_rowid();")" '4' '删除标识不复用'
assert_equal "$(query "UPDATE notes SET body='不存在' WHERE id=999; SELECT changes();")" '0' '不存在目标'

# 后续语句失败后必须整体回滚，且 -bail 不继续执行。
if "$memo_sqlite" -batch -bail -init /dev/null "$memo_db" > "$test_root/error.log" 2>&1 <<'SQL'
BEGIN IMMEDIATE;
INSERT INTO notes(category,title,body) VALUES('测试','不应保留','事务测试');
INSERT INTO notes(category,title,body) VALUES('测试','','触发非空标题约束');
COMMIT;
SQL
then
  echo '失败：约束错误未导致退出。' >&2
  exit 1
fi
assert_equal "$(query "SELECT count(*) FROM notes WHERE title='不应保留';")" '0' '失败事务回滚'
if "$memo_sqlite" -batch -bail -init /dev/null "$memo_db" \
  < "$repo_root/skills/personal-memo/assets/schema.sql" > "$test_root/reinit.log" 2>&1; then
  echo '失败：重复初始化不应成功。' >&2
  exit 1
fi
assert_equal "$(query 'SELECT count(*) FROM notes;')" '3' '重复初始化不覆盖数据'
if "$memo_sqlite" -batch -bail -init /dev/null -readonly "$test_root/missing.db" \
  'SELECT 1;' > "$test_root/missing.log" 2>&1; then
  echo '失败：只读打开不存在数据库不应成功。' >&2
  exit 1
fi
test ! -e "$test_root/missing.db"
if "$memo_sqlite" -batch -bail -init /dev/null -readonly "$memo_db" \
  'DELETE FROM notes;' > "$test_root/readonly.log" 2>&1; then
  echo '失败：只读连接不应允许删除。' >&2
  exit 1
fi

(
  cd "$test_root"
  "$memo_sqlite" -batch -bail -init /dev/null -readonly "$memo_db" '.backup person.memo.backup.db'
)
assert_equal "$("$memo_sqlite" -batch -bail -init /dev/null -readonly "$test_root/person.memo.backup.db" \
  'PRAGMA integrity_check; SELECT count(*) FROM notes;')" $'ok\n3' '备份可读与数据完整'
assert_equal "$(query 'PRAGMA integrity_check;')" 'ok' '源库完整性'
printf '[ok] personal-memo：功能探测、正文往返、分类时间检索、修改删除、失败回滚、只读与备份；%s\n' "$memo_sqlite"
