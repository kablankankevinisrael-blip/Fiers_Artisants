import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PortfolioItem } from './schemas/portfolio-item.schema';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';

@Injectable()
export class PortfolioService {
  constructor(
    @InjectModel(PortfolioItem.name)
    private readonly portfolioModel: Model<PortfolioItem>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
  ) {}

  async create(userId: string, dto: any): Promise<PortfolioItem> {
    const profile = await this.artisanProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) throw new NotFoundException('Profil artisan non trouvé.');

    return this.portfolioModel.create({
      artisanProfileId: profile.id,
      ...dto,
    });
  }

  async findMyItems(userId: string): Promise<PortfolioItem[]> {
    const profile = await this.artisanProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) throw new NotFoundException('Profil artisan non trouvé.');

    return this.portfolioModel
      .find({ artisanProfileId: profile.id })
      .sort({ createdAt: -1 })
      .exec();
  }

  async findByArtisan(artisanId: string): Promise<PortfolioItem[]> {
    return this.portfolioModel
      .find({ artisanProfileId: artisanId })
      .sort({ createdAt: -1 })
      .exec();
  }

  async update(
    userId: string,
    itemId: string,
    dto: any,
  ): Promise<PortfolioItem> {
    const profile = await this.artisanProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) throw new NotFoundException('Profil artisan non trouvé.');

    const item = await this.portfolioModel.findById(itemId).exec();
    if (!item) throw new NotFoundException('Réalisation non trouvée.');
    if (item.artisanProfileId !== profile.id) {
      throw new ForbiddenException('Accès non autorisé.');
    }

    Object.assign(item, dto);
    return item.save();
  }

  async remove(userId: string, itemId: string): Promise<void> {
    const profile = await this.artisanProfileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) throw new NotFoundException('Profil artisan non trouvé.');

    const item = await this.portfolioModel.findById(itemId).exec();
    if (!item) throw new NotFoundException('Réalisation non trouvée.');
    if (item.artisanProfileId !== profile.id) {
      throw new ForbiddenException('Accès non autorisé.');
    }

    await this.portfolioModel.findByIdAndDelete(itemId).exec();
  }
}
