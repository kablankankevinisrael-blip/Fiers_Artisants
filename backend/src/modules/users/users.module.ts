import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController, PublicArtisanController } from './users.controller';
import { User } from './entities/user.entity';
import { ArtisanProfile } from './entities/artisan-profile.entity';
import { ClientProfile } from './entities/client-profile.entity';
import { FavoriteArtisan } from './entities/favorite-artisan.entity';
import { AnalyticsModule } from '../analytics/analytics.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      ArtisanProfile,
      ClientProfile,
      FavoriteArtisan,
    ]),
    AnalyticsModule,
  ],
  controllers: [UsersController, PublicArtisanController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
