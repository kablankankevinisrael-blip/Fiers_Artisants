import { registerAs } from '@nestjs/config';

export default registerAs('app', () => {
  const defaultCorsOrigins = [
    'http://localhost:3000',
    'http://localhost:3001',
    'http://localhost:3002',
    'http://localhost:5050',
    'http://127.0.0.1:5050',
  ];
  const envCorsOrigins =
    process.env.CORS_ORIGINS
      ?.split(',')
      .map((origin) => origin.trim())
      .filter(Boolean) || [];

  return {
    nodeEnv: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.APP_PORT || '3000', 10),
    appUrl: process.env.APP_URL || 'http://localhost:3000',
    corsOrigins: Array.from(new Set([...envCorsOrigins, ...defaultCorsOrigins])),
  };
});
