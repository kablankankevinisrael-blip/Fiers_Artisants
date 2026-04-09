'use client';

import { useEffect, useRef } from 'react';
import { resolveApiUrl } from '@/lib/api';

const POLL_INTERVAL = 30_000;

/**
 * Shared hook: subscribes to the admin verification SSE stream.
 * Falls back to polling if SSE disconnects.
 * Refreshes on visibility change.
 *
 * @param onEvent — called on each SSE message (or poll tick) so the
 *                  consuming page can reload its own data.
 */
export function useAdminSSE(onEvent: () => void) {
  const onEventRef = useRef(onEvent);
  useEffect(() => {
    onEventRef.current = onEvent;
  });

  useEffect(() => {
    let es: EventSource | null = null;
    let fallbackId: ReturnType<typeof setInterval> | null = null;
    let disposed = false;

    const fire = () => onEventRef.current();

    const startPolling = () => {
      if (!fallbackId && !disposed) {
        fallbackId = setInterval(fire, POLL_INTERVAL);
      }
    };
    const stopPolling = () => {
      if (fallbackId) {
        clearInterval(fallbackId);
        fallbackId = null;
      }
    };

    const startSSE = () => {
      if (disposed) return;
      const token =
        typeof window !== 'undefined'
          ? localStorage.getItem('admin_token')
          : null;
      const baseUrl = resolveApiUrl();
      const url = `${baseUrl}/admin/verifications/events${token ? `?token=${token}` : ''}`;
      es = new EventSource(url);

      es.onmessage = () => fire();

      es.onerror = () => {
        es?.close();
        es = null;
        startPolling();
      };

      // SSE connected — stop fallback polling
      stopPolling();
    };

    const onVisibility = () => {
      if (document.visibilityState === 'visible') {
        fire();
        if (!es && !disposed) startSSE();
      } else {
        es?.close();
        es = null;
        stopPolling();
      }
    };

    if (document.visibilityState === 'visible') {
      startSSE();
    }
    document.addEventListener('visibilitychange', onVisibility);

    return () => {
      disposed = true;
      es?.close();
      stopPolling();
      document.removeEventListener('visibilitychange', onVisibility);
    };
  }, []);
}
