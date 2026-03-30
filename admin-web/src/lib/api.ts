import axios from 'axios';
import type {
  AuthResponse,
  DashboardStats,
  VerificationDocument,
  ArtisanProfile,
  AnalyticsData,
} from '@/types';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Unwrap backend envelope {statusCode, data, timestamp}
api.interceptors.response.use((response) => {
  const body = response.data;
  if (
    body &&
    typeof body === 'object' &&
    'data' in body &&
    'statusCode' in body &&
    'timestamp' in body
  ) {
    response.data = body.data;
  }
  return response;
});

// Inject JWT
api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

// Auth
export async function loginAdmin(phone: string, password: string): Promise<AuthResponse> {
  const { data } = await api.post<AuthResponse>('/auth/login', {
    phone_number: phone,
    password,
  });
  return data;
}

// Dashboard
export async function getDashboardStats(): Promise<DashboardStats> {
  const { data } = await api.get<DashboardStats>('/admin/dashboard');
  return data;
}

// Verifications
export async function getPendingVerifications(): Promise<VerificationDocument[]> {
  const { data } = await api.get<VerificationDocument[]>('/admin/verifications/pending');
  return data;
}

export async function reviewDocument(
  id: string,
  status: 'APPROVED' | 'REJECTED',
  rejectionReason?: string
): Promise<void> {
  await api.put(`/admin/verifications/${id}`, {
    status,
    rejection_reason: rejectionReason,
  });
}

// Artisans
export async function getArtisans(): Promise<ArtisanProfile[]> {
  const { data } = await api.get<ArtisanProfile[]>('/admin/artisans');
  return data;
}

// Analytics
export async function getAnalytics(): Promise<AnalyticsData> {
  const { data } = await api.get<AnalyticsData>('/admin/analytics');
  return data;
}

export default api;
