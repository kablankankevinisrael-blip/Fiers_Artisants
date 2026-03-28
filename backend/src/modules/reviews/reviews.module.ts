import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReviewsService } from './reviews.service';
import { ReviewsController, ArtisanReviewsController } from './reviews.controller';
import { Review } from './entities/review.entity';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { ClientProfile } from '../users/entities/client-profile.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Review, ArtisanProfile, ClientProfile]),
  ],
  controllers: [ReviewsController, ArtisanReviewsController],
  providers: [ReviewsService],
  exports: [ReviewsService],
})
export class ReviewsModule {}
