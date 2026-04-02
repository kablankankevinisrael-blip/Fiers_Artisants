import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../data/repositories/verification_repository.dart';

/// Max extra pages allowed for DIPLOME/CERTIFICAT/ATTESTATION
const int kMaxExtraPages = 5;

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final VerificationRepository _repo = VerificationRepository();

  bool _loading = true;
  String? _error;

  String _identityStatus = 'none';
  String? _identityRejectionReason;
  String _diplomaStatus = 'none';
  String? _diplomaRejectionReason;

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
        } else if (type == 'DIPLOME' ||
            type == 'CERTIFICAT' ||
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

  void _showDocumentTypePicker({required bool isIdentity}) {
    final types = isIdentity
        ? [('CNI', 'CNI'), ('PASSPORT', 'Passeport')]
        : [
            ('DIPLOME', 'Diplôme'),
            ('CERTIFICAT', 'Certificat'),
            ('ATTESTATION', 'Attestation'),
          ];

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
                  _openDocumentBuilder(
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

  void _openDocumentBuilder({
    required String documentType,
    required bool isIdentity,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DocumentBuilderScreen(
          documentType: documentType,
          repo: _repo,
          onSubmitted: () {
            _loadStatus();
          },
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

// ─── Document Builder Screen ──────────────────────────────────────────────────

class _DocumentBuilderScreen extends StatefulWidget {
  final String documentType;
  final VerificationRepository repo;
  final VoidCallback onSubmitted;

  const _DocumentBuilderScreen({
    required this.documentType,
    required this.repo,
    required this.onSubmitted,
  });

  @override
  State<_DocumentBuilderScreen> createState() => _DocumentBuilderScreenState();
}

class _DocumentBuilderScreenState extends State<_DocumentBuilderScreen> {
  final ImagePicker _picker = ImagePicker();

  // CNI slots
  File? _frontFile;
  File? _backFile;

  // Passport / Diploma single main
  File? _mainFile;

  // Extra pages for diploma-like docs
  final List<File> _extraFiles = [];

  bool _submitting = false;

  bool get _isCNI => widget.documentType == 'CNI';
  bool get _isPassport => widget.documentType == 'PASSPORT';
  bool get _isDiplomaLike =>
      widget.documentType == 'DIPLOME' ||
      widget.documentType == 'CERTIFICAT' ||
      widget.documentType == 'ATTESTATION';

  bool get _isComplete {
    if (_isCNI) return _frontFile != null && _backFile != null;
    if (_isPassport) return _mainFile != null;
    if (_isDiplomaLike) return _mainFile != null;
    return false;
  }

  String get _documentLabel {
    switch (widget.documentType) {
      case 'CNI':
        return 'CNI';
      case 'PASSPORT':
        return 'Passeport';
      case 'DIPLOME':
        return 'Diplôme';
      case 'CERTIFICAT':
        return 'Certificat';
      case 'ATTESTATION':
        return 'Attestation';
      default:
        return widget.documentType;
    }
  }

  Future<File?> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<void> _submit() async {
    if (!_isComplete || _submitting) return;
    setState(() => _submitting = true);

    try {
      final List<Map<String, dynamic>> files = [];

      if (_isCNI) {
        final front = await widget.repo.uploadDocument(_frontFile!.path);
        final back = await widget.repo.uploadDocument(_backFile!.path);
        files.add({
          'file_url': front['url'],
          'object_key': front['objectKey'],
          'page_role': 'FRONT',
          'page_order': 0,
        });
        files.add({
          'file_url': back['url'],
          'object_key': back['objectKey'],
          'page_role': 'BACK',
          'page_order': 1,
        });
      } else if (_isPassport) {
        final main = await widget.repo.uploadDocument(_mainFile!.path);
        files.add({
          'file_url': main['url'],
          'object_key': main['objectKey'],
          'page_role': 'MAIN',
          'page_order': 0,
        });
      } else if (_isDiplomaLike) {
        final main = await widget.repo.uploadDocument(_mainFile!.path);
        files.add({
          'file_url': main['url'],
          'object_key': main['objectKey'],
          'page_role': 'MAIN',
          'page_order': 0,
        });
        for (int i = 0; i < _extraFiles.length; i++) {
          final extra =
              await widget.repo.uploadDocument(_extraFiles[i].path);
          files.add({
            'file_url': extra['url'],
            'object_key': extra['objectKey'],
            'page_role': 'EXTRA',
            'page_order': i + 1,
          });
        }
      }

      await widget.repo.submitDocumentWithFiles(
        documentType: widget.documentType,
        files: files,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('artisan.verification.upload_success'.tr()),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSubmitted();
        Navigator.of(context).pop();
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_documentLabel)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Completion indicator
          _buildProgressIndicator(theme),
          const SizedBox(height: 24),

          if (_isCNI) ..._buildCNISlots(theme),
          if (_isPassport) ..._buildPassportSlot(theme),
          if (_isDiplomaLike) ..._buildDiplomaSlots(theme),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isComplete && !_submitting ? _submit : null,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _submitting
                    ? 'artisan.verification.submitting'.tr()
                    : 'artisan.verification.submit_document'.tr(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    final Color color;
    final String text;
    final IconData icon;

    if (_isComplete) {
      color = AppTheme.success;
      text = 'Dossier complet — prêt à envoyer';
      icon = Icons.check_circle_outline;
    } else {
      color = AppTheme.warning;
      text = 'Dossier incomplet';
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CNI: Recto + Verso ───────────────────────────────────────────────

  List<Widget> _buildCNISlots(ThemeData theme) {
    return [
      Text(
        'Veuillez fournir le recto et le verso de votre CNI',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      _ImageSlot(
        label: 'Recto (face avant)',
        file: _frontFile,
        required: true,
        onPick: () async {
          final f = await _pickImage();
          if (f != null) setState(() => _frontFile = f);
        },
        onRemove: () => setState(() => _frontFile = null),
      ),
      const SizedBox(height: 12),
      _ImageSlot(
        label: 'Verso (face arrière)',
        file: _backFile,
        required: true,
        onPick: () async {
          final f = await _pickImage();
          if (f != null) setState(() => _backFile = f);
        },
        onRemove: () => setState(() => _backFile = null),
      ),
    ];
  }

  // ─── Passport: 1 image ────────────────────────────────────────────────

  List<Widget> _buildPassportSlot(ThemeData theme) {
    return [
      Text(
        'Veuillez fournir la page principale de votre passeport',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      _ImageSlot(
        label: 'Page principale',
        file: _mainFile,
        required: true,
        onPick: () async {
          final f = await _pickImage();
          if (f != null) setState(() => _mainFile = f);
        },
        onRemove: () => setState(() => _mainFile = null),
      ),
    ];
  }

  // ─── Diploma/Certificat/Attestation: main + extras ────────────────────

  List<Widget> _buildDiplomaSlots(ThemeData theme) {
    return [
      Text(
        'Ajoutez la page principale puis les pages additionnelles si nécessaire',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      _ImageSlot(
        label: 'Page principale (obligatoire)',
        file: _mainFile,
        required: true,
        onPick: () async {
          final f = await _pickImage();
          if (f != null) setState(() => _mainFile = f);
        },
        onRemove: () => setState(() => _mainFile = null),
      ),
      const SizedBox(height: 16),
      Text(
        'Pages additionnelles (${_extraFiles.length}/$kMaxExtraPages)',
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      ...List.generate(_extraFiles.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ImageSlot(
            label: 'Page ${i + 2}',
            file: _extraFiles[i],
            required: false,
            onPick: () async {
              final f = await _pickImage();
              if (f != null) {
                setState(() => _extraFiles[i] = f);
              }
            },
            onRemove: () => setState(() => _extraFiles.removeAt(i)),
          ),
        );
      }),
      if (_extraFiles.length < kMaxExtraPages)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: OutlinedButton.icon(
            onPressed: () async {
              final f = await _pickImage();
              if (f != null) setState(() => _extraFiles.add(f));
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Ajouter une page'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.gold,
              side: BorderSide(
                color: AppTheme.gold.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
    ];
  }
}

// ─── Image Slot Widget ────────────────────────────────────────────────────────

class _ImageSlot extends StatelessWidget {
  final String label;
  final File? file;
  final bool required;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImageSlot({
    required this.label,
    required this.file,
    required this.required,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = file != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile
              ? AppTheme.success.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: hasFile ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (required)
                        Text(
                          ' *',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasFile) ...[
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    tooltip: 'Remplacer',
                    onPressed: onPick,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: AppTheme.error),
                    tooltip: 'Supprimer',
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),

          // Image preview or pick button
          if (hasFile)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            InkWell(
              onTap: onPick,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Appuyer pour choisir',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Verification Step Widget (unchanged) ─────────────────────────────────────

class _VerificationStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final String? rejectionReason;
  final VoidCallback? onTap;

  const _VerificationStep({
    required this.icon,
    required this.title,
    required this.status,
    this.rejectionReason,
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
      onTap: onTap,
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
              child: Icon(icon, color: statusColor),
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
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
