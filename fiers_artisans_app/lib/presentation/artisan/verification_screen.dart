import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/theme.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('artisan.verification.title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VerificationStep(
              icon: Icons.badge_outlined,
              title: 'artisan.verification.upload_id'.tr(),
              status: 'pending',
              onTap: () {
                // TODO: Image picker for ID
              },
            ),
            const SizedBox(height: 16),
            _VerificationStep(
              icon: Icons.school_outlined,
              title: 'artisan.verification.upload_diploma'.tr(),
              status: 'none',
              onTap: () {
                // TODO: Image picker for diploma
              },
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
  final String status; // 'none', 'pending', 'approved', 'rejected'
  final VoidCallback onTap;

  const _VerificationStep({
    required this.icon,
    required this.title,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved':
        statusColor = AppTheme.success;
        statusText = 'artisan.verification.approved'.tr();
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusText = 'artisan.verification.pending'.tr();
        break;
      case 'rejected':
        statusColor = AppTheme.error;
        statusText = 'artisan.verification.rejected'.tr();
        break;
      default:
        statusColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
        statusText = 'Télécharger';
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
                  Text(statusText,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: statusColor)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
