'use client';

import { useState, useEffect, useCallback } from 'react';

type Messages = Record<string, Record<string, string>>;

let cachedMessages: Messages | null = null;
let cachedLocale: string | null = null;

async function loadMessages(locale: string): Promise<Messages> {
  if (cachedMessages && cachedLocale === locale) return cachedMessages;
  const mod = await import(`@/messages/${locale}.json`);
  cachedMessages = mod.default;
  cachedLocale = locale;
  return cachedMessages!;
}

export function useTranslations(namespace?: string) {
  const [locale, setLocaleState] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('admin_locale') || process.env.NEXT_PUBLIC_DEFAULT_LOCALE || 'fr';
    }
    return process.env.NEXT_PUBLIC_DEFAULT_LOCALE || 'fr';
  });
  const [messages, setMessages] = useState<Messages | null>(null);

  useEffect(() => {
    loadMessages(locale).then(setMessages);
  }, [locale]);

  const t = useCallback(
    (key: string): string => {
      if (!messages) return key;
      const fullKey = namespace ? `${namespace}.${key}` : key;
      const parts = fullKey.split('.');
      let current: unknown = messages;
      for (const part of parts) {
        if (current && typeof current === 'object' && part in current) {
          current = (current as Record<string, unknown>)[part];
        } else {
          return fullKey;
        }
      }
      return typeof current === 'string' ? current : fullKey;
    },
    [messages, namespace]
  );

  const setLocale = useCallback((newLocale: string) => {
    localStorage.setItem('admin_locale', newLocale);
    cachedMessages = null;
    setLocaleState(newLocale);
  }, []);

  return { t, locale, setLocale };
}
