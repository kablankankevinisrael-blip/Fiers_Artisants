import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  OneToMany,
  Index,
} from 'typeorm';
import { ArtisanProfile } from './artisan-profile.entity';
import { ClientProfile } from './client-profile.entity';
import { VerificationDocument } from '../../verification/entities/verification-document.entity';

export enum UserRole {
  ARTISAN = 'ARTISAN',
  CLIENT = 'CLIENT',
  ADMIN = 'ADMIN',
}

export enum VerificationStatus {
  PENDING = 'PENDING',
  VERIFIED = 'VERIFIED',
  CERTIFIED = 'CERTIFIED',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @Index()
  phone_number: string;

  @Column({ nullable: true })
  email: string;

  @Column()
  password_hash: string;

  @Column({ type: 'enum', enum: UserRole })
  role: UserRole;

  @Column({
    type: 'enum',
    enum: VerificationStatus,
    default: VerificationStatus.PENDING,
  })
  verification_status: VerificationStatus;

  @Column({ default: true })
  is_active: boolean;

  @Column({ default: false })
  is_phone_verified: boolean;

  @Column({ nullable: true })
  whatsapp_number: string;

  @Column({ default: 'CI' })
  country_code: string;

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true,
  })
  location: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;

  @OneToOne(() => ArtisanProfile, (profile) => profile.user, { nullable: true })
  artisan_profile: ArtisanProfile;

  @OneToOne(() => ClientProfile, (profile) => profile.user, { nullable: true })
  client_profile: ClientProfile;

  @OneToMany(() => VerificationDocument, (doc) => doc.user)
  verification_documents: VerificationDocument[];
}
