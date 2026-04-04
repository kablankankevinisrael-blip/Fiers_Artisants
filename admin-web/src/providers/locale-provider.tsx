'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';

type Messages = Record<string, unknown>;

interface LocaleContextValue {
  locale: string;
  messages: Messages | null;
  setLocale: (locale: string) => void;
}

const LocaleContext = createContext<LocaleContextValue | null>(null);

let cachedMessages: Messages | null = null;
let cachedLocale: string | null = null;

async function loadMessages(locale: string): Promise<Messages> {
  if (cachedMessages && cachedLocale === locale) return cachedMessages;
  const mod = await import(`@/messages/${locale}.json`);
  cachedMessages = mod.default;
  cachedLocale = locale;
  return cachedMessages!;
}

const DEFAULT_LOCALE = process.env.NEXT_PUBLIC_DEFAULT_LOCALE || 'fr';

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState(DEFAULT_LOCALE);

  useEffect(() => {
    const saved = localStorage.getItem('admin_locale');
    if (saved && saved !== locale) {
      setLocaleState(saved);
    }
  }, []);
  const [messages, setMessages] = useState<Messages | null>(null);

  useEffect(() => {
    loadMessages(locale).then(setMessages);
    // Sync <html lang> attribute with current locale
    document.documentElement.lang = locale;
  }, [locale]);

  const setLocale = useCallback((newLocale: string) => {
    localStorage.setItem('admin_locale', newLocale);
    cachedMessages = null;
    setLocaleState(newLocale);
  }, []);

  return (
    <LocaleContext.Provider value={{ locale, messages, setLocale }}>
      {children}
    </LocaleContext.Provider>
  );
}

export function useLocaleContext(): LocaleContextValue {
  const ctx = useContext(LocaleContext);
  if (!ctx) throw new Error('useLocaleContext must be used within LocaleProvider');
  return ctx;
}
