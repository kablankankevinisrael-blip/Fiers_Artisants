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

function getInitialLocale(): string {
  if (typeof window !== 'undefined') {
    return localStorage.getItem('admin_locale') || process.env.NEXT_PUBLIC_DEFAULT_LOCALE || 'fr';
  }
  return process.env.NEXT_PUBLIC_DEFAULT_LOCALE || 'fr';
}

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState(getInitialLocale);
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
