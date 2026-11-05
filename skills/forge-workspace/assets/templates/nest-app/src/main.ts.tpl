import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { z } from 'zod';
import { AppModule } from './app.module.js';

const EnvironmentSchema = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().int().min(1).max(65535).default(__PORT__),
  HOST: z.string().default('127.0.0.1'),
});

async function bootstrap() {
  const environment = EnvironmentSchema.parse(process.env);
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.enableShutdownHooks();
  await app.listen(environment.PORT, environment.HOST);
}

bootstrap().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
