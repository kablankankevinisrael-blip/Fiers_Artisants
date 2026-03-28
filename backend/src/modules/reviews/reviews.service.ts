import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from './entities/review.entity';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { ClientProfile } from '../users/entities/client-profile.entity';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    @InjectRepository(ClientProfile)
    private readonly clientProfileRepository: Repository<ClientProfile>,
  ) {}

  async create(userId: string, dto: CreateReviewDto): Promise<Review> {
    // Récupérer le profil client
    const clientProfile = await this.clientProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (!clientProfile) {
      throw new NotFoundException('Profil client non trouvé.');
    }

    // Vérifier l'unicité : un seul avis par client par artisan
    const existing = await this.reviewRepository.findOne({
      where: { client_id: clientProfile.id, artisan_id: dto.artisan_id },
    });
    if (existing) {
      throw new ConflictException(
        'Vous avez déjà laissé un avis pour cet artisan.',
      );
    }

    // Créer l'avis
    const review = this.reviewRepository.create({
      client_id: clientProfile.id,
      artisan_id: dto.artisan_id,
      rating: dto.rating,
      comment: dto.comment,
    });
    const saved = await this.reviewRepository.save(review);

    // Recalculer la note moyenne de l'artisan
    await this.updateArtisanRating(dto.artisan_id);

    return saved;
  }

  async findByArtisan(artisanId: string): Promise<Review[]> {
    return this.reviewRepository.find({
      where: { artisan_id: artisanId },
      relations: ['client'],
      order: { created_at: 'DESC' },
    });
  }

  private async updateArtisanRating(artisanId: string): Promise<void> {
    const result = await this.reviewRepository
      .createQueryBuilder('review')
      .select('AVG(review.rating)', 'avg')
      .addSelect('COUNT(review.id)', 'count')
      .where('review.artisan_id = :artisanId', { artisanId })
      .getRawOne();

    await this.artisanProfileRepository.update(artisanId, {
      rating_avg: parseFloat(result.avg) || 0,
      total_reviews: parseInt(result.count, 10) || 0,
    });
  }
}
