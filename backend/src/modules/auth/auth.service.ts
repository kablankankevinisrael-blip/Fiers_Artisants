import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/entities/user.entity';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { ClientProfile } from '../users/entities/client-profile.entity';
import { OtpService } from './otp/otp.service';
import {
  RegisterArtisanDto,
  RegisterClientDto,
  LoginDto,
} from './dto/auth.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    @InjectRepository(ClientProfile)
    private readonly clientProfileRepository: Repository<ClientProfile>,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly otpService: OtpService,
  ) {}

  async registerArtisan(dto: RegisterArtisanDto) {
    // Vérifier l'unicité du numéro
    const existing = await this.userRepository.findOne({
      where: { phone_number: dto.phone_number },
    });
    if (existing) {
      throw new ConflictException('Ce numéro de téléphone est déjà utilisé.');
    }

    // Créer l'utilisateur
    const password_hash = await bcrypt.hash(dto.password, 12);
    const user = this.userRepository.create({
      phone_number: dto.phone_number,
      password_hash,
      role: UserRole.ARTISAN,
      whatsapp_number: dto.whatsapp_number || dto.phone_number,
    });
    const savedUser = await this.userRepository.save(user);

    // Créer le profil artisan
    const profile = this.artisanProfileRepository.create({
      user_id: savedUser.id,
      first_name: dto.first_name,
      last_name: dto.last_name,
      business_name: dto.business_name,
      city: dto.city,
      commune: dto.commune,
      whatsapp_number: dto.whatsapp_number || dto.phone_number,
    });
    await this.artisanProfileRepository.save(profile);

    this.logger.log(`Artisan registered: ${savedUser.id}`);
    return { user_id: savedUser.id, role: UserRole.ARTISAN };
  }

  async registerClient(dto: RegisterClientDto) {
    const existing = await this.userRepository.findOne({
      where: { phone_number: dto.phone_number },
    });
    if (existing) {
      throw new ConflictException('Ce numéro de téléphone est déjà utilisé.');
    }

    const password_hash = await bcrypt.hash(dto.password, 12);
    const user = this.userRepository.create({
      phone_number: dto.phone_number,
      password_hash,
      role: UserRole.CLIENT,
      whatsapp_number: dto.phone_number,
    });
    const savedUser = await this.userRepository.save(user);

    const profile = this.clientProfileRepository.create({
      user_id: savedUser.id,
      first_name: dto.first_name,
      last_name: dto.last_name,
      city: dto.city,
      commune: dto.commune,
    });
    await this.clientProfileRepository.save(profile);

    this.logger.log(`Client registered: ${savedUser.id}`);
    return { user_id: savedUser.id, role: UserRole.CLIENT };
  }

  async sendOtp(phoneNumber: string) {
    return this.otpService.sendOtp(phoneNumber);
  }

  async verifyOtp(phoneNumber: string, code: string) {
    await this.otpService.verifyOtp(phoneNumber, code);

    // Marquer le téléphone comme vérifié
    await this.userRepository.update(
      { phone_number: phoneNumber },
      { is_phone_verified: true },
    );

    return { verified: true };
  }

  async login(dto: LoginDto) {
    const user = await this.userRepository.findOne({
      where: { phone_number: dto.phone_number },
    });
    if (!user) {
      throw new UnauthorizedException('Identifiants invalides.');
    }

    const isPasswordValid = await bcrypt.compare(
      dto.password,
      user.password_hash,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Identifiants invalides.');
    }

    if (!user.is_active) {
      throw new UnauthorizedException('Compte désactivé.');
    }

    return this.generateTokens(user);
  }

  async refreshToken(userId: string) {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user || !user.is_active) {
      throw new UnauthorizedException('Token invalide.');
    }
    return this.generateTokens(user);
  }

  private generateTokens(user: User) {
    const payload = {
      sub: user.id,
      phone_number: user.phone_number,
      role: user.role,
    };

    const access_token = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.secret') || 'fallback',
      expiresIn: (this.configService.get<string>('jwt.accessExpiration') || '15m') as any,
    });

    const refresh_token = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.refreshSecret') || 'fallback',
      expiresIn: (this.configService.get<string>('jwt.refreshExpiration') || '30d') as any,
    });

    return {
      access_token,
      refresh_token,
      user: {
        id: user.id,
        phone_number: user.phone_number,
        role: user.role,
        verification_status: user.verification_status,
      },
    };
  }
}
