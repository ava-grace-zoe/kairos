import { expect, it } from 'vitest';
import { normalizeLabel } from './index.js';

it('清理空白，保留文字和词间间隔', () => {
  expect(normalizeLabel('  Hello   工程  ')).toBe('Hello 工程');
  expect(normalizeLabel('   ')).toBe('');
});
