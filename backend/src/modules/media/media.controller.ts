import {
  Controller,
  Post,
  Get,
  Param,
  Query,
  Res,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  NotFoundException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { MediaService } from './media.service';
import { CurrentUser } from '../../common/decorators';
import { PhoneVerifiedGuard } from '../../common/guards';

@Controller('media')
@UseGuards(AuthGuard('jwt'), PhoneVerifiedGuard)
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  async upload(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File,
    @Query('bucket') bucket: string,
  ) {
    const media = await this.mediaService.upload(userId, bucket, file);
    const url = await this.mediaService.getSignedUrl(media.bucket, media.objectKey);
    const thumbnailUrl = media.thumbnailKey
      ? await this.mediaService.getSignedUrl(media.bucket, media.thumbnailKey)
      : null;

    return {
      id: media._id,
      url,
      objectKey: media.objectKey,
      bucket: media.bucket,
      thumbnailUrl,
      originalName: media.originalName,
      mimeType: media.mimeType,
      size: media.size,
    };
  }

  @Get('file/:bucket/:objectKey')
  async streamFile(
    @Param('bucket') bucket: string,
    @Param('objectKey') objectKey: string,
    @Res() res: Response,
  ) {
    try {
      const { stream, contentType, size } = await this.mediaService.streamFile(
        bucket,
        objectKey,
      );
      res.set({
        'Content-Type': contentType,
        'Content-Length': size.toString(),
        'Cache-Control': 'private, max-age=3600',
        'Content-Disposition': 'inline',
      });
      (stream as NodeJS.ReadableStream).pipe(res);
    } catch {
      throw new NotFoundException('Fichier introuvable.');
    }
  }
}
