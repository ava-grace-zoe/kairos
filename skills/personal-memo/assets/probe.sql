-- 仅在 :memory: 内存数据库运行，失败即表示所需基础能力不满足。
BEGIN;
CREATE TABLE capability_probe (ok INTEGER NOT NULL CHECK(ok = 1));
INSERT INTO capability_probe VALUES (
    instr('中文关键词 % _', '关键词') > 0
    AND instr('中文关键词 % _', '% _') > 0
    AND strftime('%Y-%m-%dT%H:%M:%SZ', '2026-11-05T00:00:00+08:00')
        = '2026-11-04T16:00:00Z'
);
COMMIT;
SELECT 'ok' AS capability FROM capability_probe;
