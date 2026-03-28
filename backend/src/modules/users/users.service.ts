import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { ArtisanProfile } from './entities/artisan-profile.entity';
import { ClientProfile } from './entities/client-profile.entity';
import { UpdateArtisanProfileDto } from './dto/update-artisan-profile.dto';
import { UpdateClientProfileDto } from './dto/update-client-profile.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    @InjectRepository(ClientProfile)
    private readonly clientProfileRepository: Repository<ClientProfile>,
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
      relations: ['category', 'user'],
    });
    if (!profile) {
      throw new NotFoundException('Profil artisan non trouvé.');
    }
    return profile;
  }

  async getArtisanPublicProfile(artisanId: string): Promise<ArtisanProfile> {
    const profile = await this.artisanProfileRepository.findOne({
      where: { id: artisanId, is_subscription_active: true },
      relations: ['category', 'user'],
    });
    if (!profile) {
      throw new NotFoundException('Artisan non trouvé ou non actif.');
    }
    return profile;
  }

  async updateArtisanProfile(
    userId: string,
    dto: UpdateArtisanProfileDto,
  ): Promise<ArtisanProfile> {
    const profile = await this.getArtisanProfile(userId);
    Object.assign(profile, dto);
    return this.artisanProfileRepository.save(profile);
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

  async updateUserLocation(
    userId: string,
    lat: number,
    lng: number,
  ): Promise<void> {
    await this.userRepository
      .createQueryBuilder()
      .update(User)
      .set({
        location: () => `ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`,
      })
      .where('id = :id', { id: userId })
      .execute();
  }
}
