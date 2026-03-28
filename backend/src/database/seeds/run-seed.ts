import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import { resolve } from 'path';
import { seedCategories } from './categories.seed';
import { Category } from '../../modules/categories/entities/category.entity';
import { Subcategory } from '../../modules/categories/entities/subcategory.entity';

// Load .env from project root
config({ path: resolve(__dirname, '../../../../.env') });

async function run() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.POSTGRES_HOST || 'localhost',
    port: parseInt(process.env.POSTGRES_PORT || '5434', 10),
    username: process.env.POSTGRES_USER || 'fiers_artisans',
    password: process.env.POSTGRES_PASSWORD || 'fiers_dev_2025',
    database: process.env.POSTGRES_DB || 'fiers_artisans',
    entities: [Category, Subcategory],
  });

  await dataSource.initialize();
  console.log('📦 Connected to PostgreSQL');

  await seedCategories(dataSource);

  await dataSource.destroy();
  console.log('🏁 Seed complete');
}

run().catch((err) => {
  console.error('❌ Seed failed:', err.message);
  process.exit(1);
});
