import {
  IsString,
  IsEnum,
  IsPhoneNumber,
  MinLength,
  IsOptional,
} from 'class-validator';
import { UserRole } from '../../users/entities/user.entity';

export class RegisterArtisanDto {
  @IsString()
  phone_number: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  first_name: string;

  @IsString()
  last_name: string;

  @IsOptional()
  @IsString()
  business_name?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  commune?: string;

  @IsOptional()
  @IsString()
  whatsapp_number?: string;
}

export class RegisterClientDto {
  @IsString()
  phone_number: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  first_name: string;

  @IsString()
  last_name: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  commune?: string;
}

export class SendOtpDto {
  @IsString()
  phone_number: string;
}

export class VerifyOtpDto {
  @IsString()
  phone_number: string;

  @IsString()
  code: string;
}

export class LoginDto {
  @IsString()
  phone_number: string;

  @IsString()
  password: string;
}

export class RefreshTokenDto {
  @IsString()
  refresh_token: string;
}
