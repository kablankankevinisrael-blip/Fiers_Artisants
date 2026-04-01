import {
  Controller,
  Get,
  Put,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AdminService } from './admin.service';
import { CurrentUser, Roles } from '../../common/decorators';
import { RolesGuard } from '../../common/guards';
import { ReviewDocumentDto } from '../verification/dto/review-document.dto';

@Controller('admin')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('ADMIN')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  getDashboard() {
    return this.adminService.getDashboardStats();
  }

  @Get('verifications/pending')
  getPendingVerifications() {
    return this.adminService.getPendingVerifications();
  }

  @Put('verifications/:id')
  reviewDocument(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') adminId: string,
    @Body() dto: ReviewDocumentDto,
  ) {
    return this.adminService.reviewDocument(id, adminId, dto);
  }

  @Get('artisans')
  listArtisans() {
    return this.adminService.listArtisans();
  }

  @Get('analytics')
  getAnalytics() {
    return this.adminService.getAnalytics();
  }

  // ── Clients ─────────────────────────────────────────────────
  @Get('clients')
  listClients() {
    return this.adminService.listClients();
  }

  // ── Subscriptions ───────────────────────────────────────────
  @Get('subscriptions')
  listSubscriptions() {
    return this.adminService.listSubscriptions();
  }

  // ── Reviews ─────────────────────────────────────────────────
  @Get('reviews')
  listReviews() {
    return this.adminService.listReviews();
  }

  @Delete('reviews/:id')
  deleteReview(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.deleteReview(id);
  }

  // ── Activity Logs ───────────────────────────────────────────
  @Get('logs')
  getLogs(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('action') action?: string,
  ) {
    return this.adminService.getLogs(page || 1, limit || 50, action);
  }
}
