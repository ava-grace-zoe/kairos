import { mkdirSync } from 'node:fs';
import pg from 'pg';
import { chromium } from 'playwright';
import { describe, expect, it } from 'vitest';

const api = process.env.TEST_API_URL;
const web = process.env.TEST_WEB_URL;
const databaseUrl = process.env.DATABASE_URL;
if (!api || !web || !databaseUrl)
  throw new Error('请通过 pnpm test:system 运行，启动器负责隔离资源。');

describe('构建产物的前后端完整链路', () => {
  it('后端拒绝非法输入，并把有效记录真正写入数据库', async () => {
    const invalid = await fetch(`${api}/api/notes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: '  ' }),
    });
    expect(invalid.status).toBe(400);
    const title = `接口验收-${crypto.randomUUID()}`;
    const response = await fetch(`${api}/api/notes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title }),
    });
    expect(response.status).toBe(201);
    const note = await response.json();
    expect(note.title).toBe(title);
    const url = new URL(databaseUrl);
    const schema = url.searchParams.get('schema');
    if (!schema || !/^forge_test_[a-f0-9]+$/.test(schema))
      throw new Error('拒绝访问非测试数据库模式');
    const database = new pg.Client({ connectionString: databaseUrl });
    await database.connect();
    try {
      const result = await database.query(`SELECT title FROM "${schema}"."Note" WHERE id = $1`, [
        note.id,
      ]);
      expect(result.rows).toEqual([{ title }]);
    } finally {
      await database.end();
    }
  });

  it('浏览器保存记录，刷新后仍存在，路由导航正常', async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    const errors: string[] = [];
    page.on('pageerror', (error) => errors.push(error.message));
    try {
      await page.goto(web);
      await page.getByRole('heading', { name: '让想法，有处可放。' }).waitFor();
      const title = `浏览器验收-${crypto.randomUUID()}`;
      await page.getByLabel('新的记录').fill(title);
      await page.getByRole('button', { name: '保存记录', exact: true }).click();
      await page.getByText(title, { exact: true }).waitFor();
      await page.reload();
      await page.getByText(title, { exact: true }).waitFor();
      mkdirSync('test-results', { recursive: true });
      await page.screenshot({ path: 'test-results/workspace-desktop.png', fullPage: true });
      await page.setViewportSize({ width: 390, height: 844 });
      expect(
        await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
      ).toBe(true);
      await page.screenshot({ path: 'test-results/workspace-mobile.png', fullPage: true });
      await page.getByRole('link', { name: '关于', exact: true }).click();
      await page.getByRole('heading', { name: '关于这个空间' }).waitFor();
      expect(errors).toEqual([]);
    } finally {
      await browser.close();
    }
  });
});
