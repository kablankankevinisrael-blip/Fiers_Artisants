'use client';

import { useState, useCallback } from 'react';
import { loginAdmin } from '@/lib/api';
import { saveAuth, getUser, getToken, logout as clearAuth } from '@/lib/auth';
import type { User } from '@/types';

export function useAuth() {
  const [user, setUser] = useState<User | null>(() => {
    if (typeof window === 'undefined') return null;
    const token = getToken();
    const savedUser = getUser();
    if (token && savedUser && savedUser.role === 'ADMIN') return savedUser;
    return null;
  });
  const [loading] = useState(false);

  const login = useCallback(async (phone: string, password: string) => {
    const data = await loginAdmin(phone, password);
    if (data.user.role !== 'ADMIN') {
      throw new Error('NOT_ADMIN');
    }
    saveAuth(data.access_token, data.refresh_token, data.user);
    setUser(data.user);
  }, []);

  const logout = useCallback(() => {
    clearAuth();
    setUser(null);
    window.location.href = '/login';
  }, []);

  return { user, loading, login, logout, isAuthenticated: !!user };
}
