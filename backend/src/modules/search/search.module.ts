import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SearchService } from './search.service';
import { SearchController } from './search.controller';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ArtisanProfile])],
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
