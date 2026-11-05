import { expect, it } from 'vitest';
import { createDatabase } from './index.js';

it('非法连接地址在创建客户端时立即失败', () => {
  expect(() => createDatabase('无效地址')).toThrow();
});
