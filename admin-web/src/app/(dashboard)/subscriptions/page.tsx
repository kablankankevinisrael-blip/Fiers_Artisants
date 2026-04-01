'use client';

import { useEffect, useState, useMemo } from 'react';
import { getSubscriptions } from '@/lib/api';
import { useTranslations } from '@/hooks/use-translations';
import { Badge } from '@/components/ui/badge';
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { CreditCard } from 'lucide-react';
import { toast } from 'sonner';
import type { SubscriptionRecord } from '@/types';

export default function SubscriptionsPage() {
  const [subscriptions, setSubscriptions] = useState<SubscriptionRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('all');
  const { t } = useTranslations('subscriptions');
  const { t: tApp } = useTranslations('app');

  useEffect(() => {
    (async () => {
      try {
        const data = await getSubscriptions();
        setSubscriptions(data);
      } catch {
        toast.error(tApp('error'));
      } finally {
        setLoading(false);
      }
    })();
  }, [tApp]);

  const filtered = useMemo(() => {
    return subscriptions.filter((s) => {
      return statusFilter === 'all' || s.status === statusFilter;
    });
  }, [subscriptions, statusFilter]);

  const statusBadge = (status: string) => {
    switch (status) {
      case 'ACTIVE':
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">Active</Badge>;
      case 'EXPIRED':
        return <Badge variant="destructive">Expired</Badge>;
      case 'PENDING':
        return <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200">Pending</Badge>;
      case 'CANCELLED':
        return <Badge variant="secondary">Cancelled</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const getLastPaymentDate = (payments: SubscriptionRecord['payments']) => {
    const successful = payments
      .filter((p) => p.status === 'SUCCESS')
      .sort((a, b) => new Date(b.paid_at).getTime() - new Date(a.paid_at).getTime());
    return successful.length > 0
      ? new Date(successful[0].paid_at).toLocaleDateString('fr-FR')
      : t('no_payment');
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{t('title')}</h2>
        <p className="text-muted-foreground">{t('subtitle')}</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v ?? 'all')}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder={t('filter_status')} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('filter_all')}</SelectItem>
            <SelectItem value="ACTIVE">Active</SelectItem>
            <SelectItem value="EXPIRED">Expired</SelectItem>
            <SelectItem value="PENDING">Pending</SelectItem>
            <SelectItem value="CANCELLED">Cancelled</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CreditCard className="h-5 w-5" />
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
            <p className="text-center text-muted-foreground py-8">{t('no_subscriptions')}</p>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>{t('artisan')}</TableHead>
                    <TableHead>{t('plan')}</TableHead>
                    <TableHead>{t('status')}</TableHead>
                    <TableHead>{t('amount')}</TableHead>
                    <TableHead>{t('start_date')}</TableHead>
                    <TableHead>{t('expiry_date')}</TableHead>
                    <TableHead>{t('last_payment')}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filtered.map((s) => (
                    <TableRow key={s.id}>
                      <TableCell className="font-medium">
                        {s.artisan_profile?.first_name} {s.artisan_profile?.last_name}
                      </TableCell>
                      <TableCell>{s.plan}</TableCell>
                      <TableCell>{statusBadge(s.status)}</TableCell>
                      <TableCell>{s.amount_fcfa?.toLocaleString('fr-FR')} FCFA</TableCell>
                      <TableCell>
                        {new Date(s.starts_at).toLocaleDateString('fr-FR')}
                      </TableCell>
                      <TableCell>
                        {new Date(s.expires_at).toLocaleDateString('fr-FR')}
                      </TableCell>
                      <TableCell>
                        {getLastPaymentDate(s.payments || [])}
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
