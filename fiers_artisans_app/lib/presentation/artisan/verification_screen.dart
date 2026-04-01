import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../data/repositories/verification_repository.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final VerificationRepository _repo = VerificationRepository();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  String? _error;

  // Per-section state
  String _identityStatus = 'none'; // none, PENDING, APPROVED, REJECTED
  String? _identityRejectionReason;
  String _diplomaStatus = 'none';
  String? _diplomaRejectionReason;

  bool _uploadingIdentity = false;
  bool _uploadingDiploma = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getVerificationStatus();
      final docs = data['documents'] as List<dynamic>? ?? [];

      String idStatus = 'none';
      String? idReason;
      String dipStatus = 'none';
      String? dipReason;

      for (final doc in docs) {
        final type = doc['document_type'] as String? ?? '';
        final status = doc['status'] as String? ?? '';
        final reason = doc['rejection_reason'] as String?;

        if (type == 'CNI' || type == 'PASSPORT') {
          idStatus = status;
          idReason = reason;
        } else if (type == 'DIPLOME' || type == 'CERTIFICAT' ||
            type == 'ATTESTATION') {
          dipStatus = status;
          dipReason = reason;
        }
      }

      setState(() {
        _identityStatus = idStatus;
        _identityRejectionReason = idReason;
        _diplomaStatus = dipStatus;
        _diplomaRejectionReason = dipReason;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _uploadDocument({
    required String documentType,
    required bool isIdentity,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      if (isIdentity) {
        _uploadingIdentity = true;
      } else {
        _uploadingDiploma = true;
      }
    });

    try {
      final fileUrl = await _repo.uploadDocument(picked.path);
      await _repo.submitDocument(
        documentType: documentType,
        fileUrl: fileUrl,
      );
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('artisan.verification.upload_success'.tr()),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('artisan.verification.upload_error'.tr()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isIdentity) {
            _uploadingIdentity = false;
          } else {
            _uploadingDiploma = false;
          }
        });
      }
    }
  }

  void _showDocumentTypePicker({required bool isIdentity}) {
    final types = isIdentity
        ? [('CNI', 'CNI'), ('PASSPORT', 'Passeport')]
        : [
            ('DIPLOME', 'Diplôme'),
            ('CERTIFICAT', 'Certificat'),
            ('ATTESTATION', 'Attestation'),
          ];

    if (types.length == 1) {
      _uploadDocument(documentType: types.first.$1, isIdentity: isIdentity);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'artisan.verification.select_type'.tr(),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...types.map(
              (t) => ListTile(
                title: Text(t.$2),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadDocument(
                    documentType: t.$1,
                    isIdentity: isIdentity,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('artisan.verification.title'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('error.generic'.tr()),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadStatus,
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStatus,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _VerificationStep(
                        icon: Icons.badge_outlined,
                        title: 'artisan.verification.upload_id'.tr(),
                        status: _identityStatus,
                        rejectionReason: _identityRejectionReason,
                        uploading: _uploadingIdentity,
                        onTap: _identityStatus == 'APPROVED'
                            ? null
                            : () =>
                                _showDocumentTypePicker(isIdentity: true),
                      ),
                      const SizedBox(height: 16),
                      _VerificationStep(
                        icon: Icons.school_outlined,
                        title: 'artisan.verification.upload_diploma'.tr(),
                        status: _diplomaStatus,
                        rejectionReason: _diplomaRejectionReason,
                        uploading: _uploadingDiploma,
                        onTap: _diplomaStatus == 'APPROVED'
                            ? null
                            : () =>
                                _showDocumentTypePicker(isIdentity: false),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status; // 'none', 'PENDING', 'APPROVED', 'REJECTED'
  final String? rejectionReason;
  final bool uploading;
  final VoidCallback? onTap;

  const _VerificationStep({
    required this.icon,
    required this.title,
    required this.status,
    this.rejectionReason,
    this.uploading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor;
    final String statusText;

    switch (status) {
      case 'APPROVED':
        statusColor = AppTheme.success;
        statusText = 'artisan.verification.approved'.tr();
      case 'PENDING':
        statusColor = AppTheme.warning;
        statusText = 'artisan.verification.pending'.tr();
      case 'REJECTED':
        statusColor = AppTheme.error;
        statusText = rejectionReason ??
            'artisan.verification.rejected'.tr();
      default:
        statusColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
        statusText = 'artisan.verification.not_submitted'.tr();
    }

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: uploading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: statusColor,
                      ),
                    )
                  : Icon(icon, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
            if (onTap != null && !uploading)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
