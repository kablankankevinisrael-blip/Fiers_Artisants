import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../modules/users/entities/user.entity';

@Injectable()
export class PhoneVerifiedGuard implements CanActivate {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.id;
    if (!userId) {
      throw new ForbiddenException('OTP_REQUIRED');
    }

    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['id', 'is_phone_verified'],
    });

    if (!user || !user.is_phone_verified) {
      throw new ForbiddenException('OTP_REQUIRED');
    }

    return true;
  }
}
