import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { ArtisanProfile } from './entities/artisan-profile.entity';
import { ClientProfile } from './entities/client-profile.entity';
import { FavoriteArtisan } from './entities/favorite-artisan.entity';
import { Subcategory } from '../categories/entities/subcategory.entity';
import { UpdateArtisanProfileDto } from './dto/update-artisan-profile.dto';
import { UpdateClientProfileDto } from './dto/update-client-profile.dto';
import { AnalyticsService } from '../analytics/analytics.service';
import { ChatGateway } from '../chat/chat.gateway';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    @InjectRepository(ClientProfile)
    private readonly clientProfileRepository: Repository<ClientProfile>,
    @InjectRepository(FavoriteArtisan)
    private readonly favoriteArtisanRepository: Repository<FavoriteArtisan>,
    @InjectRepository(Subcategory)
    private readonly subcategoryRepository: Repository<Subcategory>,
    private readonly analyticsService: AnalyticsService,
    private readonly chatGateway: ChatGateway,
  ) {}

  async findById(id: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id },
      relations: ['artisan_profile', 'client_profile'],
    });
    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé.');
    }
    return user;
  }

  async findByPhone(phone_number: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { phone_number },
      relations: ['artisan_profile', 'client_profile'],
    });
  }

  async getArtisanProfile(userId: string): Promise<ArtisanProfile> {
    const profile = await this.artisanProfileRepository.findOne({
      where: { user_id: userId },
      relations: ['category', 'subcategory', 'user'],
    });
    if (!profile) {
      throw new NotFoundException('Profil artisan non trouvé.');
    }
    return profile;
  }

  async getArtisanPublicProfile(artisanId: string): Promise<ArtisanProfile> {
    // Try by profile ID first, then by user ID (mobile sends userId)
    let profile = await this.artisanProfileRepository.findOne({
      where: { id: artisanId, is_subscription_active: true },
      relations: ['category', 'subcategory', 'user'],
    });
    if (!profile) {
      profile = await this.artisanProfileRepository.findOne({
        where: { user: { id: artisanId }, is_subscription_active: true },
        relations: ['category', 'subcategory', 'user'],
      });
    }
    if (!profile) {
      throw new NotFoundException('Artisan non trouvé ou non actif.');
    }

    this.analyticsService.logActivity({
      actorId: 'anonymous',
      action: 'PROFILE_VIEW',
      targetId: profile.id,
    }).catch(() => {});

    return profile;
  }

  async updateArtisanProfile(
    userId: string,
    dto: UpdateArtisanProfileDto,
  ): Promise<ArtisanProfile> {
    const profile = await this.getArtisanProfile(userId);
    const previousAvailability = profile.is_available;

    if (dto.subcategory_id) {
      const subcategory = await this.subcategoryRepository.findOne({
        where: { id: dto.subcategory_id },
        select: ['id', 'category_id'],
      });

      if (!subcategory) {
        throw new NotFoundException('Metier non trouve.');
      }

      const nextCategoryId = dto.category_id ?? profile.category_id;
      if (nextCategoryId && subcategory.category_id !== nextCategoryId) {
        throw new NotFoundException(
          'La categorie ne correspond pas au metier selectionne.',
        );
      }

      dto.category_id = dto.category_id ?? subcategory.category_id;
    }

    if (
      dto.category_id &&
      !dto.subcategory_id &&
      profile.subcategory_id &&
      profile.subcategory?.category_id &&
      profile.subcategory.category_id !== dto.category_id
    ) {
      dto.subcategory_id = null;
    }

    Object.assign(profile, dto);
    const savedProfile = await this.artisanProfileRepository.save(profile);

    if (
      dto.is_available !== undefined &&
      previousAvailability !== savedProfile.is_available
    ) {
      this.chatGateway
        .emitParticipantAvailabilityUpdated(
          savedProfile.user_id,
          savedProfile.is_available,
        )
        .catch(() => {});
    }

    return savedProfile;
  }

  async getArtisanStats(userId: string): Promise<{
    profile_views_48h: number;
    window_hours: number;
  }> {
    const profile = await this.getArtisanProfile(userId);
    const profileViews48h = await this.analyticsService.countProfileViewsInLastHours(
      profile.id,
      48,
    );
    return {
      profile_views_48h: profileViews48h,
      window_hours: 48,
    };
  }

  async getClientProfile(userId: string): Promise<ClientProfile> {
    const profile = await this.clientProfileRepository.findOne({
      where: { user_id: userId },
      relations: ['user'],
    });
    if (!profile) {
      throw new NotFoundException('Profil client non trouvé.');
    }
    return profile;
  }

  async updateClientProfile(
    userId: string,
    dto: UpdateClientProfileDto,
  ): Promise<ClientProfile> {
    const profile = await this.getClientProfile(userId);
    Object.assign(profile, dto);
    return this.clientProfileRepository.save(profile);
  }

  async listFavoriteArtisans(clientUserId: string): Promise<Record<string, any>[]> {
    const clientProfile = await this.getClientProfile(clientUserId);
    const favorites = await this.favoriteArtisanRepository.find({
      where: { client_profile_id: clientProfile.id },
      relations: [
        'artisan_profile',
        'artisan_profile.user',
        'artisan_profile.category',
        'artisan_profile.subcategory',
      ],
      order: { created_at: 'DESC' },
    });
    return favorites.map((favorite) => {
      const profile = favorite.artisan_profile;
      return {
        id: profile.id,
        user_id: profile.user_id,
        first_name: profile.first_name,
        last_name: profile.last_name,
        business_name: profile.business_name,
        bio: profile.bio,
        years_experience: profile.years_experience,
        city: profile.city,
        commune: profile.commune,
        rating_avg: profile.rating_avg,
        total_reviews: profile.total_reviews,
        is_available: profile.is_available,
        is_subscription_active: profile.is_subscription_active,
        category_id: profile.category_id,
        subcategory_id: profile.subcategory_id,
        category: profile.category,
        subcategory: profile.subcategory,
        created_at: profile.created_at,
        updated_at: profile.updated_at,
        user: profile.user
          ? {
              id: profile.user.id,
              phone_number: profile.user.phone_number,
              email: profile.user.email,
              verification_status: profile.user.verification_status,
            }
          : null,
      };
    });
  }

  async getFavoriteStatus(
    clientUserId: string,
    artisanIdentifier: string,
  ): Promise<{ is_favorite: boolean }> {
    const isFavorite = await this.isFavorite(clientUserId, artisanIdentifier);
    return { is_favorite: isFavorite };
  }

  async setFavoriteArtisan(
    clientUserId: string,
    artisanIdentifier: string,
    isFavorite: boolean,
  ): Promise<{ is_favorite: boolean }> {
    const clientProfile = await this.getClientProfile(clientUserId);
    const artisanProfile = await this.findArtisanProfileByIdentifier(
      artisanIdentifier,
    );

    const existing = await this.favoriteArtisanRepository.findOne({
      where: {
        client_profile_id: clientProfile.id,
        artisan_profile_id: artisanProfile.id,
      },
    });

    if (isFavorite) {
      if (!existing) {
        await this.favoriteArtisanRepository.save(
          this.favoriteArtisanRepository.create({
            client_profile_id: clientProfile.id,
            artisan_profile_id: artisanProfile.id,
          }),
        );
      }
      return { is_favorite: true };
    }

    if (existing) {
      await this.favoriteArtisanRepository.delete(existing.id);
    }
    return { is_favorite: false };
  }

  private async isFavorite(
    clientUserId: string,
    artisanIdentifier: string,
  ): Promise<boolean> {
    const clientProfile = await this.getClientProfile(clientUserId);
    const artisanProfile = await this.findArtisanProfileByIdentifier(
      artisanIdentifier,
    );
    const favorite = await this.favoriteArtisanRepository.findOne({
      where: {
        client_profile_id: clientProfile.id,
        artisan_profile_id: artisanProfile.id,
      },
      select: ['id'],
    });
    return !!favorite;
  }

  private async findArtisanProfileByIdentifier(
    artisanIdentifier: string,
  ): Promise<ArtisanProfile> {
    let profile = await this.artisanProfileRepository.findOne({
      where: { user: { id: artisanIdentifier } },
      relations: ['user', 'category', 'subcategory'],
    });

    if (!profile) {
      profile = await this.artisanProfileRepository.findOne({
        where: { id: artisanIdentifier },
        relations: ['user', 'category', 'subcategory'],
      });
    }

    if (!profile) {
      throw new NotFoundException('Artisan non trouvé.');
    }

    return profile;
  }

  async updateUserLocation(
    userId: string,
    lat: number,
    lng: number,
  ): Promise<void> {
    await this.userRepository
      .createQueryBuilder()
      .update(User)
      .set({
        location: () => 'ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)',
      })
      .where('id = :id', { id: userId })
      .setParameters({ lat, lng })
      .execute();
  }

  async updateFcmToken(userId: string, fcmToken: string): Promise<void> {
    await this.userRepository.update(userId, { fcm_token: fcmToken });
  }
}
