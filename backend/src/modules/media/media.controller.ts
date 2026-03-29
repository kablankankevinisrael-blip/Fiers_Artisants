import {
  Controller,
  Post,
  Get,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
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
      thumbnailUrl,
      originalName: media.originalName,
      mimeType: media.mimeType,
      size: media.size,
    };
  }
}
