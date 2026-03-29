// Charger .env AVANT tout import de modules NestJS
// pour que process.env soit peuplé quand les décorateurs @Module s'évaluent
import './load-env.js';

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters';
import { LoggingInterceptor, TransformInterceptor } from './common/interceptors';

async function bootstrap() {
  // ── Fail-fast: vérifier les secrets obligatoires ────────────────
  const requiredSecrets = [
    'POSTGRES_PASSWORD',
    'REDIS_PASSWORD',
    'JWT_SECRET',
    'JWT_REFRESH_SECRET',
  ];
  const missing = requiredSecrets.filter((k) => !process.env[k] || process.env[k]?.startsWith('change_me'));
  if (missing.length > 0 && process.env.NODE_ENV === 'production') {
    Logger.error(
      `Missing or insecure required secrets: ${missing.join(', ')}. Refusing to start in production.`,
      'Bootstrap',
    );
    process.exit(1);
  }
  if (missing.length > 0) {
    Logger.warn(
      `⚠️  Secrets with default values detected: ${missing.join(', ')}. Update .env before deploying.`,
      'Bootstrap',
    );
  }

  const app = await NestFactory.create(AppModule, {
    rawBody: true, // Pour la vérification HMAC du webhook Wave
  });

  const configService = app.get(ConfigService);
  const port = configService.get<number>('app.port') || 3000;
  const corsOrigins = configService.get<string[]>('app.corsOrigins') || ['*'];

  // ── Préfixe global ──────────────────────────────────────────
  app.setGlobalPrefix('api/v1', {
    exclude: ['api/docs', 'api/docs-json'],
  });

  // ── Sécurité ──────────────────────────────────────────────────
  app.use(helmet());
  app.enableCors({
    origin: corsOrigins,
    credentials: true,
  });

  // ── Pipes globaux ─────────────────────────────────────────────
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // ── Filtres et Intercepteurs globaux ──────────────────────────
  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new TransformInterceptor(),
  );

  // ── Swagger (API Documentation) ───────────────────────────────
  if (configService.get<string>('app.nodeEnv') !== 'production') {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Fiers Artisans API')
      .setDescription('API pour la plateforme Fiers Artisans — Marketplace artisans ivoiriens')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, document);
  }

  await app.listen(port);
  Logger.log(
    `🚀 Fiers Artisans API running on http://localhost:${port}`,
    'Bootstrap',
  );
  Logger.log(
    `📖 Swagger docs: http://localhost:${port}/api/docs`,
    'Bootstrap',
  );
}
bootstrap();
