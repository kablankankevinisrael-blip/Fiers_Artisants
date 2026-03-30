'use client';

import { useEffect, useState, useCallback } from 'react';
import { getPendingVerifications, reviewDocument } from '@/lib/api';
import { useTranslations } from '@/hooks/use-translations';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Textarea } from '@/components/ui/textarea';
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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { CheckCircle, XCircle, FileText, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import type { VerificationDocument } from '@/types';

export default function VerificationsPage() {
  const [docs, setDocs] = useState<VerificationDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [rejectDialog, setRejectDialog] = useState<VerificationDocument | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const { t } = useTranslations('verifications');
  const { t: tApp } = useTranslations('app');

  const loadDocs = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getPendingVerifications();
      setDocs(data);
    } catch {
      toast.error(tApp('error'));
    } finally {
      setLoading(false);
    }
  }, [tApp]);

  useEffect(() => {
    loadDocs();
  }, [loadDocs]);

  const handleApprove = async (doc: VerificationDocument) => {
    setActionLoading(true);
    try {
      await reviewDocument(doc.id, 'APPROVED');
      toast.success(t('approved_success'));
      setDocs((prev) => prev.filter((d) => d.id !== doc.id));
    } catch {
      toast.error(tApp('error'));
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!rejectDialog || !rejectReason.trim()) return;
    setActionLoading(true);
    try {
      await reviewDocument(rejectDialog.id, 'REJECTED', rejectReason.trim());
      toast.success(t('rejected_success'));
      setDocs((prev) => prev.filter((d) => d.id !== rejectDialog.id));
      setRejectDialog(null);
      setRejectReason('');
    } catch {
      toast.error(tApp('error'));
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{t('title')}</h2>
        <p className="text-muted-foreground">{t('subtitle')}</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            {t('title')}
            {!loading && (
              <Badge variant="secondary" className="ml-2">{docs.length}</Badge>
            )}
          </CardTitle>
          <CardDescription>{t('subtitle')}</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[...Array(3)].map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : docs.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">{t('no_pending')}</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t('document_type')}</TableHead>
                  <TableHead>{t('submitted_by')}</TableHead>
                  <TableHead>{t('submitted_at')}</TableHead>
                  <TableHead>{t('status')}</TableHead>
                  <TableHead className="text-right">{t('actions')}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {docs.map((doc) => (
                  <TableRow key={doc.id}>
                    <TableCell className="font-medium">{doc.document_type}</TableCell>
                    <TableCell>{doc.user?.phone_number || doc.user_id.slice(0, 8)}</TableCell>
                    <TableCell>
                      {new Date(doc.submitted_at).toLocaleDateString('fr-FR')}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">PENDING</Badge>
                    </TableCell>
                    <TableCell className="text-right space-x-2">
                      <Button
                        size="sm"
                        variant="outline"
                        className="text-green-600 hover:text-green-700"
                        onClick={() => handleApprove(doc)}
                        disabled={actionLoading}
                      >
                        <CheckCircle className="mr-1 h-4 w-4" />
                        {t('approve')}
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        className="text-destructive hover:text-destructive"
                        onClick={() => setRejectDialog(doc)}
                        disabled={actionLoading}
                      >
                        <XCircle className="mr-1 h-4 w-4" />
                        {t('reject')}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Reject dialog */}
      <Dialog open={!!rejectDialog} onOpenChange={() => { setRejectDialog(null); setRejectReason(''); }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('reject')}</DialogTitle>
            <DialogDescription>{t('confirm_reject')}</DialogDescription>
          </DialogHeader>
          <div className="space-y-2">
            <Textarea
              placeholder={t('reject_reason_placeholder')}
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
            />
            {rejectReason.trim() === '' && (
              <p className="text-xs text-destructive">{t('reject_reason_required')}</p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => { setRejectDialog(null); setRejectReason(''); }}>
              {tApp('cancel')}
            </Button>
            <Button
              variant="destructive"
              onClick={handleReject}
              disabled={!rejectReason.trim() || actionLoading}
            >
              {actionLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {t('reject')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
