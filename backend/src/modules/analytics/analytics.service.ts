import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ActivityLog } from './schemas/activity-log.schema';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectModel(ActivityLog.name)
    private readonly activityLogModel: Model<ActivityLog>,
  ) {}

  async logActivity(data: {
    actorId: string;
    action: string;
    targetId?: string;
    metadata?: Record<string, any>;
    ipAddress?: string;
    userAgent?: string;
  }): Promise<void> {
    await this.activityLogModel.create(data);
  }

  async getDashboardStats() {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [totalSearches, totalProfileViews, totalContacts, recentLogins] =
      await Promise.all([
        this.activityLogModel.countDocuments({
          action: 'SEARCH',
          timestamp: { $gte: thirtyDaysAgo },
        }),
        this.activityLogModel.countDocuments({
          action: 'PROFILE_VIEW',
          timestamp: { $gte: thirtyDaysAgo },
        }),
        this.activityLogModel.countDocuments({
          action: 'CONTACT_CLICK',
          timestamp: { $gte: thirtyDaysAgo },
        }),
        this.activityLogModel.countDocuments({
          action: 'LOGIN',
          timestamp: { $gte: thirtyDaysAgo },
        }),
      ]);

    return {
      period: '30_days',
      totalSearches,
      totalProfileViews,
      totalContacts,
      recentLogins,
    };
  }
}
