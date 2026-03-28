import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { Subscription, SubscriptionStatus } from '../subscription/entities/subscription.entity';
import { Payment, PaymentStatus } from '../subscription/entities/payment.entity';
import { VerificationService } from '../verification/verification.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { ReviewDocumentDto } from '../verification/dto/review-document.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    private readonly verificationService: VerificationService,
    private readonly analyticsService: AnalyticsService,
  ) {}

  async getDashboardStats() {
    const [
      totalUsers,
      totalArtisans,
      activeSubscriptions,
      totalRevenue,
      pendingVerifications,
    ] = await Promise.all([
      this.userRepository.count(),
      this.artisanProfileRepository.count(),
      this.subscriptionRepository.count({
        where: { status: SubscriptionStatus.ACTIVE },
      }),
      this.paymentRepository
        .createQueryBuilder('p')
        .select('COALESCE(SUM(p.amount_fcfa), 0)', 'total')
        .where('p.status = :status', { status: PaymentStatus.SUCCESS })
        .getRawOne()
        .then((r) => parseInt(r.total, 10)),
      this.verificationService.getPendingDocuments().then((d) => d.length),
    ]);

    return {
      totalUsers,
      totalArtisans,
      activeSubscriptions,
      totalRevenueFcfa: totalRevenue,
      pendingVerifications,
    };
  }

  async getPendingVerifications() {
    return this.verificationService.getPendingDocuments();
  }

  async reviewDocument(docId: string, adminId: string, dto: ReviewDocumentDto) {
    return this.verificationService.reviewDocument(docId, adminId, dto);
  }

  async listArtisans() {
    return this.artisanProfileRepository.find({
      relations: ['user', 'category', 'subscription'],
      order: { created_at: 'DESC' },
    });
  }

  async getAnalytics() {
    return this.analyticsService.getDashboardStats();
  }
}
