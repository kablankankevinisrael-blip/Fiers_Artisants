import { IsEnum, IsString } from 'class-validator';
import { DocumentType } from '../entities/verification-document.entity';

export class SubmitDocumentDto {
  @IsEnum(DocumentType)
  document_type: DocumentType;

  @IsString()
  file_url: string;
}
