import { type CreateNote, NoteSchema } from '@__SCOPE__/contracts';
import { Injectable } from '@nestjs/common';
import { DatabaseService } from './database.service.js';

@Injectable()
export class NotesService {
  constructor(private readonly database: DatabaseService) {}

  async list() {
    const notes = await this.database.client.note.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return notes.map((note) =>
      NoteSchema.parse({ ...note, createdAt: note.createdAt.toISOString() }),
    );
  }

  async create(input: CreateNote) {
    const note = await this.database.client.note.create({ data: input });
    return NoteSchema.parse({ ...note, createdAt: note.createdAt.toISOString() });
  }
}
