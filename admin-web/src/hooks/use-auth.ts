'use client';

import { useReducer, useCallback, useEffect } from 'react';
import { loginAdmin } from '@/lib/api';
import { saveAuth, getUser, getToken, logout as clearAuth } from '@/lib/auth';
import type { User } from '@/types';

interface AuthState {
  user: User | null;
  loading: boolean;
}

type AuthAction =
  | { type: 'hydrate'; user: User | null }
  | { type: 'login'; user: User }
  | { type: 'logout' };

function authReducer(state: AuthState, action: AuthAction): AuthState {
  switch (action.type) {
    case 'hydrate':
      return { user: action.user, loading: false };
    case 'login':
      return { user: action.user, loading: false };
    case 'logout':
      return { user: null, loading: false };
    default:
      return state;
  }
}

export function useAuth() {
  const [{ user, loading }, dispatch] = useReducer(authReducer, {
    user: null,
    loading: true,
  });

  useEffect(() => {
    const token = getToken();
    const savedUser = getUser();
    dispatch({
      type: 'hydrate',
      user: token && savedUser && savedUser.role === 'ADMIN' ? savedUser : null,
    });
  }, []);

  const login = useCallback(async (phone: string, pinCode: string) => {
    const data = await loginAdmin(phone, pinCode);
    if (data.user.role !== 'ADMIN') {
      throw new Error('NOT_ADMIN');
    }
    saveAuth(data.access_token, data.refresh_token, data.user);
    dispatch({ type: 'login', user: data.user });
  }, []);

  const logout = useCallback(() => {
    clearAuth();
    dispatch({ type: 'logout' });
    window.location.href = '/login';
  }, []);

  return { user, loading, login, logout, isAuthenticated: !!user };
}
