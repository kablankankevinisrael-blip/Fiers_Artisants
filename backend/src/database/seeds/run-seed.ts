import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import { resolve } from 'path';
import * as bcrypt from 'bcrypt';
import { seedCategories } from './categories.seed';
import { Category } from '../../modules/categories/entities/category.entity';
import { Subcategory } from '../../modules/categories/entities/subcategory.entity';
import { User, UserRole } from '../../modules/users/entities/user.entity';
import { ArtisanProfile } from '../../modules/users/entities/artisan-profile.entity';
import { ClientProfile } from '../../modules/users/entities/client-profile.entity';
import { VerificationDocument } from '../../modules/verification/entities/verification-document.entity';
import { Review } from '../../modules/reviews/entities/review.entity';
import { Subscription } from '../../modules/subscription/entities/subscription.entity';
import { Payment } from '../../modules/subscription/entities/payment.entity';

// Load .env from project root
config({ path: resolve(__dirname, '../../../../.env') });

async function run() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.POSTGRES_HOST || 'localhost',
    port: parseInt(process.env.POSTGRES_PORT || '5434', 10),
    username: process.env.POSTGRES_USER || 'fiers_artisans',
    password: process.env.POSTGRES_PASSWORD || 'change_me_postgres',
    database: process.env.POSTGRES_DB || 'fiers_artisans',
    entities: [Category, Subcategory, User, ArtisanProfile, ClientProfile, VerificationDocument, Review, Subscription, Payment],
  });

  await dataSource.initialize();
  console.log('📦 Connected to PostgreSQL');

  await seedCategories(dataSource);
  await seedAdmin(dataSource);

  await dataSource.destroy();
  console.log('🏁 Seed complete');
}

async function seedAdmin(dataSource: DataSource) {
  const phone = process.env.ADMIN_PHONE || '0700000000';
  const password = process.env.ADMIN_PASSWORD || 'admin123';
  const repo = dataSource.getRepository(User);

  const existing = await repo.findOne({ where: { phone_number: phone } });
  if (existing) {
    if (existing.role !== UserRole.ADMIN) {
      existing.role = UserRole.ADMIN;
      existing.is_phone_verified = true;
      await repo.save(existing);
      console.log(`🔑 User ${phone} upgraded to ADMIN`);
    } else {
      console.log(`✅ Admin ${phone} already exists`);
    }
    return;
  }

  const hash = await bcrypt.hash(password, 12);
  const admin = repo.create({
    phone_number: phone,
    password_hash: hash,
    role: UserRole.ADMIN,
    is_phone_verified: true,
    is_active: true,
  });
  await repo.save(admin);
  console.log(`🔑 Admin created: ${phone} / ${password}`);
}

run().catch((err) => {
  console.error('❌ Seed failed:', err.message);
  process.exit(1);
});
