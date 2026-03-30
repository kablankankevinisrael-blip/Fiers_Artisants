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
  document_url: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  rejection_reason?: string;
  reviewed_by?: string;
  created_at: string;
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
  rating_average: number;
  rating_count: number;
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
