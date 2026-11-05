import { Controller, Get, Module } from '@nestjs/common';
import { DatabaseService } from './database.service.js';
import { NotesController } from './notes.controller.js';
import { NotesService } from './notes.service.js';

@Controller('health')
class HealthController {
  @Get()
  check() {
    return { status: 'ok', service: '__PROJECT_NAME__' };
  }
}

@Module({
  controllers: [HealthController, NotesController],
  providers: [DatabaseService, NotesService],
})
export class AppModule {}
