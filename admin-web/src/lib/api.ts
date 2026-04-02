import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios';
import type {
  AuthResponse,
  DashboardStats,
  VerificationDocument,
  ArtisanProfile,
  AnalyticsData,
  ClientProfile,
  SubscriptionRecord,
  ReviewRecord,
  ActivityLog,
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

// Auto-refresh on 401
let isRefreshing = false;
let pendingRequests: ((token: string) => void)[] = [];

function onRefreshed(token: string) {
  pendingRequests.forEach((cb) => cb(token));
  pendingRequests = [];
}

api.interceptors.response.use(undefined, async (error: AxiosError) => {
  const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };
  if (!originalRequest || error.response?.status !== 401 || originalRequest._retry) {
    return Promise.reject(error);
  }

  // Don't refresh on login or refresh endpoint itself
  if (originalRequest.url?.includes('/auth/login') || originalRequest.url?.includes('/auth/refresh')) {
    return Promise.reject(error);
  }

  if (isRefreshing) {
    return new Promise((resolve) => {
      pendingRequests.push((token: string) => {
        originalRequest.headers.Authorization = `Bearer ${token}`;
        resolve(api(originalRequest));
      });
    });
  }

  originalRequest._retry = true;
  isRefreshing = true;

  try {
    const refreshToken = localStorage.getItem('admin_refresh_token');
    if (!refreshToken) throw new Error('No refresh token');

    const { data } = await axios.post(`${API_URL}/auth/refresh`, {}, {
      headers: { Authorization: `Bearer ${refreshToken}` },
    });

    const newToken = data?.data?.access_token || data?.access_token;
    if (!newToken) throw new Error('Invalid refresh response');

    localStorage.setItem('admin_token', newToken);
    if (data?.data?.refresh_token || data?.refresh_token) {
      localStorage.setItem('admin_refresh_token', data?.data?.refresh_token || data?.refresh_token);
    }

    originalRequest.headers.Authorization = `Bearer ${newToken}`;
    onRefreshed(newToken);
    return api(originalRequest);
  } catch {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_refresh_token');
    localStorage.removeItem('admin_user');
    if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
    return Promise.reject(error);
  } finally {
    isRefreshing = false;
  }
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

// Clients
export async function getClients(): Promise<ClientProfile[]> {
  const { data } = await api.get<ClientProfile[]>('/admin/clients');
  return data;
}

// Subscriptions
export async function getSubscriptions(): Promise<SubscriptionRecord[]> {
  const { data } = await api.get<SubscriptionRecord[]>('/admin/subscriptions');
  return data;
}

// Reviews
export async function getReviews(): Promise<ReviewRecord[]> {
  const { data } = await api.get<ReviewRecord[]>('/admin/reviews');
  return data;
}

export async function deleteReview(id: string): Promise<void> {
  await api.delete(`/admin/reviews/${id}`);
}

// Logs
export async function getLogs(
  page?: number,
  limit?: number,
  action?: string
): Promise<{ data: ActivityLog[]; total: number; page: number; limit: number }> {
  const params: Record<string, string | number> = {};
  if (page) params.page = page;
  if (limit) params.limit = limit;
  if (action) params.action = action;
  const { data } = await api.get<{ data: ActivityLog[]; total: number; page: number; limit: number }>('/admin/logs', { params });
  return data;
}

// Media — authenticated blob fetch for admin preview/download
export async function fetchFileBlob(bucket: string, objectKey: string): Promise<Blob> {
  const response = await api.get(`/media/file/${bucket}/${objectKey}`, {
    responseType: 'blob',
  });
  return response.data as Blob;
}

export default api;
