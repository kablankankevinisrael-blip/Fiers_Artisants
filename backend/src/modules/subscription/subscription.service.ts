import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription, SubscriptionStatus } from './entities/subscription.entity';
import { Payment, PaymentStatus } from './entities/payment.entity';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { WaveProvider, WaveCheckoutSession } from './providers/wave.provider';

@Injectable()
export class SubscriptionService {
  private readonly logger = new Logger(SubscriptionService.name);

  constructor(
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    private readonly waveProvider: WaveProvider,
  ) {}

  async initiatePayment(userId: string): Promise<WaveCheckoutSession> {
    const profile = await this.artisanProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) {
      throw new NotFoundException('Profil artisan non trouvé.');
    }

    // Créer ou récupérer la subscription
    let subscription = await this.subscriptionRepository.findOne({
      where: { artisan_profile_id: profile.id },
    });

    if (!subscription) {
      subscription = this.subscriptionRepository.create({
        artisan_profile_id: profile.id,
        amount_fcfa: 5000,
      });
      subscription = await this.subscriptionRepository.save(subscription);
    }

    // Créer le paiement
    const payment = this.paymentRepository.create({
      subscription_id: subscription.id,
      amount_fcfa: 5000,
    });
    await this.paymentRepository.save(payment);

    // Créer la session Wave
    return this.waveProvider.createCheckoutSession(subscription.id, 5000);
  }

  async handleWaveWebhook(
    payload: any,
    rawBody: string,
    signature: string,
  ): Promise<void> {
    // 1. Vérifier la signature HMAC-SHA256
    if (!this.waveProvider.verifyWebhookSignature(rawBody, signature)) {
      throw new BadRequestException('Signature invalide.');
    }

    const transactionId = payload.transaction_id || payload.id;
    const merchantRef = payload.merchant_reference;

    // 2. Idempotence : ignorer si déjà traité
    const existingPayment = await this.paymentRepository.findOne({
      where: { wave_transaction_id: transactionId },
    });
    if (existingPayment?.status === PaymentStatus.SUCCESS) {
      this.logger.log(`Webhook déjà traité pour transaction ${transactionId}`);
      return;
    }

    // 3. Traiter le paiement
    const subscription = await this.subscriptionRepository.findOne({
      where: { id: merchantRef },
    });
    if (!subscription) {
      this.logger.error(`Subscription non trouvée : ${merchantRef}`);
      return;
    }

    if (payload.payment_status === 'succeeded') {
      // Mettre à jour le paiement
      await this.paymentRepository.update(
        { subscription_id: subscription.id, status: PaymentStatus.PENDING },
        {
          status: PaymentStatus.SUCCESS,
          wave_transaction_id: transactionId,
          wave_checkout_id: payload.checkout_session_id,
          paid_at: new Date(),
        },
      );

      // Activer l'abonnement (30 jours)
      const now = new Date();
      const expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
      await this.subscriptionRepository.update(subscription.id, {
        status: SubscriptionStatus.ACTIVE,
        starts_at: now,
        expires_at: expiresAt,
      });

      // Activer le profil artisan
      await this.artisanProfileRepository.update(
        subscription.artisan_profile_id,
        { is_subscription_active: true },
      );

      this.logger.log(
        `Abonnement activé pour artisan ${subscription.artisan_profile_id}`,
      );
    } else {
      await this.paymentRepository.update(
        { subscription_id: subscription.id, status: PaymentStatus.PENDING },
        { status: PaymentStatus.FAILED },
      );
    }
  }

  async getStatus(userId: string) {
    const profile = await this.artisanProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) {
      throw new NotFoundException('Profil artisan non trouvé.');
    }

    const subscription = await this.subscriptionRepository.findOne({
      where: { artisan_profile_id: profile.id },
      relations: ['payments'],
      order: { created_at: 'DESC' },
    });

    return {
      subscription,
      is_active: profile.is_subscription_active,
    };
  }

  async getAvailableProviders() {
    const { PAYMENT_PROVIDERS } = require('./payment-providers.config');
    return Object.entries(PAYMENT_PROVIDERS)
      .filter(([, config]: [string, any]) => config.enabled)
      .map(([key, config]: [string, any]) => ({
        id: key,
        label: config.label,
      }));
  }
}
