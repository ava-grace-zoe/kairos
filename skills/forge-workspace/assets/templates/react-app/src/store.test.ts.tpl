import { beforeEach, expect, it } from 'vitest';
import { useViewStore } from './store.js';

beforeEach(() => useViewStore.setState({ query: '' }));

it('不同组件读取同一份筛选条件', () => {
  useViewStore.getState().setQuery('工程');
  expect(useViewStore.getState().query).toBe('工程');
});
