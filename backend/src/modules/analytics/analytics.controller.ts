import { Controller, Post, Body, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AnalyticsService } from './analytics.service';

class LogEventDto {
  action: string;
  targetId?: string;
  metadata?: Record<string, any>;
}

@Controller('analytics')
@UseGuards(AuthGuard('jwt'))
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Post('log')
  async logEvent(@Body() dto: LogEventDto, @Req() req: any) {
    await this.analyticsService.logActivity({
      actorId: req.user.id || req.user.sub,
      action: dto.action,
      targetId: dto.targetId,
      metadata: dto.metadata,
      ipAddress: req.ip,
      userAgent: req.headers?.['user-agent'],
    });
    return { logged: true };
  }
}
