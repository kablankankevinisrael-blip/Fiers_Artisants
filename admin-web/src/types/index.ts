export interface User {
  id: string;
  phone_number: string;
  email?: string;
  role: 'ADMIN' | 'ARTISAN' | 'CLIENT';
  verification_status: 'PENDING' | 'VERIFIED' | 'CERTIFIED';
  is_active: boolean;
  is_phone_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  user: User;
}

export interface DashboardStats {
  totalUsers: number;
  totalArtisans: number;
  activeSubscriptions: number;
  totalRevenueFcfa: number;
  pendingVerifications: number;
}

export interface VerificationDocument {
  id: string;
  user_id: string;
  document_type: string;
  file_url: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  rejection_reason?: string;
  reviewed_by?: string;
  submitted_at: string;
  updated_at: string;
  user?: User;
}

export interface ArtisanProfile {
  id: string;
  user_id: string;
  first_name: string;
  last_name: string;
  business_name: string;
  city: string;
  commune: string;
  whatsapp_number: string;
  bio?: string;
  rating_avg: number;
  total_reviews: number;
  is_available: boolean;
  created_at: string;
  user?: User;
  category?: { id: string; name: string };
  subscription?: {
    id: string;
    status: 'ACTIVE' | 'EXPIRED' | 'CANCELLED' | 'PENDING';
    expires_at: string;
  };
}

export interface AnalyticsData {
  period: string;
  totalSearches: number;
  totalProfileViews: number;
  totalContacts: number;
  recentLogins: number;
}

export interface ClientProfile {
  id: string;
  first_name: string;
  last_name: string;
  city: string;
  commune: string;
  created_at: string;
  user: {
    id: string;
    phone_number: string;
    is_active: boolean;
    is_phone_verified: boolean;
    verification_status: string;
  };
}

export interface SubscriptionRecord {
  id: string;
  artisan_profile_id: string;
  plan: string;
  amount_fcfa: number;
  status: 'ACTIVE' | 'EXPIRED' | 'CANCELLED' | 'PENDING';
  starts_at: string;
  expires_at: string;
  auto_renew: boolean;
  created_at: string;
  artisan_profile: {
    id: string;
    first_name: string;
    last_name: string;
    business_name: string;
    user: {
      phone_number: string;
    };
  };
  payments: {
    id: string;
    amount_fcfa: number;
    status: 'PENDING' | 'SUCCESS' | 'FAILED';
    paid_at: string;
  }[];
}

export interface ReviewRecord {
  id: string;
  rating: number;
  comment: string;
  created_at: string;
  client: {
    id: string;
    first_name: string;
    last_name: string;
  };
  artisan: {
    id: string;
    first_name: string;
    last_name: string;
    business_name: string;
  };
}

export interface ActivityLog {
  _id: string;
  actorId: string;
  action: 'SEARCH' | 'PROFILE_VIEW' | 'CONTACT_CLICK' | 'LOGIN' | 'PAYMENT_ATTEMPT' | 'REGISTRATION';
  targetId?: string;
  metadata?: Record<string, unknown>;
  timestamp: string;
}
