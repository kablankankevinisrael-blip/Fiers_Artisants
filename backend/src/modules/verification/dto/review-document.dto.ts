import { IsEnum, IsOptional, IsString } from 'class-validator';
import { DocumentStatus } from '../entities/verification-document.entity';

export class ReviewDocumentDto {
  @IsEnum([DocumentStatus.APPROVED, DocumentStatus.REJECTED])
  status: DocumentStatus;

  @IsOptional()
  @IsString()
  rejection_reason?: string;
}
