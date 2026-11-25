-- 只用于新建备忘录；不要对已有或未知数据库重复执行。
BEGIN IMMEDIATE;
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL CHECK(length(trim(category)) > 0),
    title TEXT NOT NULL CHECK(length(trim(title)) > 0),
    body TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX notes_category_updated ON notes(category, updated_at);
CREATE INDEX notes_created ON notes(created_at);
CREATE INDEX notes_updated ON notes(updated_at);
PRAGMA user_version = 1;
COMMIT;
