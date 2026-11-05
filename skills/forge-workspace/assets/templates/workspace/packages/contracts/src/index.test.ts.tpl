import { describe, expect, it } from 'vitest';
import { CreateNoteSchema, NoteSchema } from './index.js';

describe('记录契约', () => {
  it('清理首尾空格并保留有效标题', () => {
    expect(CreateNoteSchema.parse({ title: '  第一个想法  ' })).toEqual({ title: '第一个想法' });
  });
  it.each(['', '   ', '字'.repeat(121)])('拒绝空标题或超长标题：%s', (title) => {
    expect(CreateNoteSchema.safeParse({ title }).success).toBe(false);
  });
  it('拒绝未声明字段，避免把内部字段当作输入', () => {
    expect(CreateNoteSchema.safeParse({ title: '有效', id: '伪造' }).success).toBe(false);
  });
  it('接口时间采用字符串形式', () => {
    expect(
      NoteSchema.safeParse({ id: crypto.randomUUID(), title: '记录', createdAt: new Date() })
        .success,
    ).toBe(false);
  });
});
