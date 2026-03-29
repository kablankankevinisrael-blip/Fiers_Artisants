import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionService } from './subscription.service';
import { SubscriptionController } from './subscription.controller';
import { Subscription } from './entities/subscription.entity';
import { Payment } from './entities/payment.entity';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { User } from '../users/entities/user.entity';
import { WaveProvider } from './providers/wave.provider';

@Module({
  imports: [
    TypeOrmModule.forFeature([Subscription, Payment, ArtisanProfile, User]),
  ],
  controllers: [SubscriptionController],
  providers: [SubscriptionService, WaveProvider],
  exports: [SubscriptionService],
})
export class SubscriptionModule {}
