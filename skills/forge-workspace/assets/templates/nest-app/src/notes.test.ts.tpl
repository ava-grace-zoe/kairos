import 'reflect-metadata';
import { BadRequestException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { DatabaseService } from './database.service.js';
import { NotesController } from './notes.controller.js';
import { NotesService } from './notes.service.js';

describe('记录接口与构造器注入', () => {
  afterEach(() => vi.restoreAllMocks());

  it('测试模块注入服务并返回可序列化的契约', async () => {
    const note = { id: crypto.randomUUID(), title: '测试记录', createdAt: new Date() };
    const create = vi.fn().mockResolvedValue(note);
    const module = await Test.createTestingModule({
      controllers: [NotesController],
      providers: [
        NotesService,
        { provide: DatabaseService, useValue: { client: { note: { create } } } },
      ],
    }).compile();
    try {
      const controller = module.get(NotesController);
      expect(await controller.create({ title: '  测试记录 ' })).toEqual({
        ...note,
        createdAt: note.createdAt.toISOString(),
      });
      expect(create).toHaveBeenCalledWith({ data: { title: '测试记录' } });
      expect(() => controller.create({ title: '' })).toThrow(BadRequestException);
      expect(create).toHaveBeenCalledTimes(1);
    } finally {
      await module.close();
    }
  });
});
