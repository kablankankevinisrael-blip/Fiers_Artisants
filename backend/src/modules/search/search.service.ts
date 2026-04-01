import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { SearchArtisansDto } from './dto/search-artisans.dto';
import { AnalyticsService } from '../analytics/analytics.service';

@Injectable()
export class SearchService {
  constructor(
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    private readonly analyticsService: AnalyticsService,
  ) {}

  async searchArtisans(dto: SearchArtisansDto) {
    const { lat, lng, radius_km = 10, category, query, page = 1, limit = 20 } = dto;
    const offset = (page - 1) * limit;

    let qb = this.artisanProfileRepository
      .createQueryBuilder('ap')
      .innerJoinAndSelect('ap.user', 'u')
      .leftJoinAndSelect('ap.category', 'c')
      .where('ap.is_subscription_active = :active', { active: true })
      .andWhere('u.is_active = :isActive', { isActive: true })
      // PostGIS : filtrer par rayon en km
      .andWhere(
        `ST_DWithin(
          u.location::geography,
          ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
          :radius
        )`,
        { lat, lng, radius: radius_km * 1000 },
      )
      // Ajouter la distance calculée
      .addSelect(
        `ST_Distance(
          u.location::geography,
          ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography
        )`,
        'distance_meters',
      );

    if (category) {
      // Accept both category slug and UUID id from mobile
      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(category);
      if (isUuid) {
        qb = qb.andWhere('c.id = :category', { category });
      } else {
        qb = qb.andWhere('c.slug = :category', { category });
      }
    }

    if (query) {
      qb = qb.andWhere(
        `(ap.first_name ILIKE :query OR ap.last_name ILIKE :query OR ap.business_name ILIKE :query)`,
        { query: `%${query}%` },
      );
    }

    const [results, total] = await qb
      .orderBy('distance_meters', 'ASC')
      .skip(offset)
      .take(limit)
      .getManyAndCount();

    // Fire-and-forget analytics
    this.analyticsService.logActivity({
      actorId: 'anonymous',
      action: 'SEARCH',
      metadata: { category, query, lat, lng, results: total },
    }).catch(() => {});

    return {
      data: results,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
