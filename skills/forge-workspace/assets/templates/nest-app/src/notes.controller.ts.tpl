import { CreateNoteSchema } from '@__SCOPE__/contracts';
import { BadRequestException, Body, Controller, Get, Post } from '@nestjs/common';
import { NotesService } from './notes.service.js';

@Controller('notes')
export class NotesController {
  constructor(private readonly notes: NotesService) {}

  @Get()
  list() {
    return this.notes.list();
  }

  @Post()
  create(@Body() body: unknown) {
    const result = CreateNoteSchema.safeParse(body);
    if (!result.success)
      throw new BadRequestException({ message: '输入不符合接口契约', issues: result.error.issues });
    return this.notes.create(result.data);
  }
}
