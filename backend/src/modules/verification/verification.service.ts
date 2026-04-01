import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  VerificationDocument,
  DocumentStatus,
} from './entities/verification-document.entity';
import { User, VerificationStatus } from '../users/entities/user.entity';
import { SubmitDocumentDto } from './dto/submit-document.dto';
import { ReviewDocumentDto } from './dto/review-document.dto';

@Injectable()
export class VerificationService {
  constructor(
    @InjectRepository(VerificationDocument)
    private readonly docRepository: Repository<VerificationDocument>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async submitDocument(
    userId: string,
    dto: SubmitDocumentDto,
  ): Promise<VerificationDocument> {
    const doc = this.docRepository.create({
      user_id: userId,
      document_type: dto.document_type,
      file_url: dto.file_url,
    });
    return this.docRepository.save(doc);
  }

  async getVerificationStatus(userId: string) {
    const documents = await this.docRepository.find({
      where: { user_id: userId },
      order: { submitted_at: 'DESC' },
    });
    const user = await this.userRepository.findOne({ where: { id: userId } });
    return {
      verification_status: user!.verification_status,
      documents,
    };
  }

  async getPendingDocuments() {
    return this.docRepository.find({
      where: { status: DocumentStatus.PENDING },
      relations: ['user'],
      order: { submitted_at: 'ASC' },
    });
  }

  async reviewDocument(
    docId: string,
    adminId: string,
    dto: ReviewDocumentDto,
  ): Promise<VerificationDocument> {
    const doc = await this.docRepository.findOne({
      where: { id: docId },
      relations: ['user'],
    });
    if (!doc) {
      throw new NotFoundException('Document non trouvé.');
    }
    if (doc.status !== DocumentStatus.PENDING) {
      throw new BadRequestException('Ce document a déjà été traité.');
    }

    doc.status = dto.status;
    doc.reviewed_by = adminId;
    doc.reviewed_at = new Date();
    if (dto.status === DocumentStatus.REJECTED && dto.rejection_reason) {
      doc.rejection_reason = dto.rejection_reason;
    }

    const saved = await this.docRepository.save(doc);

    // Mettre à jour le statut de vérification de l'utilisateur
    if (dto.status === DocumentStatus.APPROVED) {
      await this.updateUserVerificationStatus(doc.user_id);
    }

    return saved;
  }

  private async updateUserVerificationStatus(userId: string): Promise<void> {
    const docs = await this.docRepository.find({
      where: { user_id: userId, status: DocumentStatus.APPROVED },
    });

    const hasCNI = docs.some(
      (d) => d.document_type === 'CNI' || d.document_type === 'PASSPORT',
    );
    const hasDiploma = docs.some(
      (d) =>
        d.document_type === 'DIPLOME' ||
        d.document_type === 'CERTIFICAT' ||
        d.document_type === 'ATTESTATION',
    );

    let newStatus = VerificationStatus.PENDING;
    if (hasCNI && hasDiploma) {
      newStatus = VerificationStatus.CERTIFIED;
    } else if (hasCNI) {
      newStatus = VerificationStatus.VERIFIED;
    }

    await this.userRepository.update(userId, {
      verification_status: newStatus,
    });
  }
}
