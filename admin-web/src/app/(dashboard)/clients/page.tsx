'use client';

import { useEffect, useState, useMemo } from 'react';
import { getClients } from '@/lib/api';
import { useTranslations } from '@/hooks/use-translations';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Users, Search } from 'lucide-react';
import { toast } from 'sonner';
import type { ClientProfile } from '@/types';

export default function ClientsPage() {
  const [clients, setClients] = useState<ClientProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const { t } = useTranslations('clients');
  const { t: tApp } = useTranslations('app');

  useEffect(() => {
    (async () => {
      try {
        const data = await getClients();
        setClients(data);
      } catch {
        toast.error(tApp('error'));
      } finally {
        setLoading(false);
      }
    })();
  }, [tApp]);

  const filtered = useMemo(() => {
    return clients.filter((c) => {
      if (!search) return true;
      return `${c.first_name} ${c.last_name}`
        .toLowerCase()
        .includes(search.toLowerCase());
    });
  }, [clients, search]);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{t('title')}</h2>
        <p className="text-muted-foreground">{t('subtitle')}</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder={tApp('search')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            {t('title')}
            {!loading && (
              <Badge variant="secondary" className="ml-2">{filtered.length}</Badge>
            )}
          </CardTitle>
          <CardDescription>{t('subtitle')}</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[...Array(5)].map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">{t('no_clients')}</p>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>{t('name')}</TableHead>
                    <TableHead>{t('phone')}</TableHead>
                    <TableHead>{t('city')}</TableHead>
                    <TableHead>{t('status')}</TableHead>
                    <TableHead>{t('verified')}</TableHead>
                    <TableHead>{t('joined')}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filtered.map((c) => (
                    <TableRow key={c.id}>
                      <TableCell className="font-medium">
                        {c.first_name} {c.last_name}
                      </TableCell>
                      <TableCell>{c.user?.phone_number || '—'}</TableCell>
                      <TableCell>{c.city}{c.commune ? `, ${c.commune}` : ''}</TableCell>
                      <TableCell>
                        {c.user?.is_active ? (
                          <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">{t('active')}</Badge>
                        ) : (
                          <Badge variant="destructive">{t('inactive')}</Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        {c.user?.is_phone_verified ? (
                          <Badge className="bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">{t('yes')}</Badge>
                        ) : (
                          <Badge variant="outline">{t('no')}</Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        {new Date(c.created_at).toLocaleDateString('fr-FR')}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
