import { beforeEach, expect, it } from 'vitest';
import { page } from 'vitest/browser';
import { render } from 'vitest-browser-react';
import { NotesList } from './notes-list.js';
import { useViewStore } from './store.js';

beforeEach(() => useViewStore.setState({ query: '' }));

it('在真实浏览器中通过筛选输入更新记录列表', async () => {
  await render(
    <NotesList
      notes={[
        { id: crypto.randomUUID(), title: '工程规范', createdAt: new Date().toISOString() },
        { id: crypto.randomUUID(), title: '周末计划', createdAt: new Date().toISOString() },
      ]}
    />,
  );
  await page.getByRole('textbox', { name: '筛选记录' }).fill('工程');
  await expect.element(page.getByText('工程规范')).toBeVisible();
  await expect.element(page.getByText('周末计划')).not.toBeInTheDocument();
});
