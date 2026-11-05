import { createDatabase } from '@__SCOPE__/database';
import { Injectable, type OnModuleDestroy } from '@nestjs/common';

@Injectable()
export class DatabaseService implements OnModuleDestroy {
  readonly client = createDatabase(
    process.env.DATABASE_URL ?? 'postgresql://forge:forge_local@127.0.0.1:54329/__WORKSPACE__',
  );

  async onModuleDestroy() {
    await this.client.$disconnect();
  }
}
