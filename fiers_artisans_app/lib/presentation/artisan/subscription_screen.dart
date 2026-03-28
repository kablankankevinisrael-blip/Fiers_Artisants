import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/theme.dart';
import '../../providers/subscription_provider.dart';
import '../common/app_button.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: Text('subscription.title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Subscription card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium,
                      size: 56, color: Colors.black),
                  const SizedBox(height: 16),
                  Text(
                    'subscription.amount'.tr(),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subState.subscription?.isActive == true
                        ? 'subscription.active'.tr()
                        : 'subscription.expired'.tr(),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  if (subState.subscription?.isActive == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      'subscription.expires_in'.tr(namedArgs: {
                        'days':
                            '${subState.subscription!.daysRemaining}'
                      }),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            if (subState.subscription?.isActive != true)
              AppButton(
                text: 'subscription.pay'.tr(),
                icon: Icons.payment,
                isLoading: subState.isLoading,
                onPressed: () async {
                  final data = await ref
                      .read(subscriptionProvider.notifier)
                      .initiatePayment();
                  if (data != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Redirection vers Wave...')),
                    );
                  }
                },
              )
            else
              AppButton(
                text: 'subscription.renew'.tr(),
                isOutlined: true,
                onPressed: () async {
                  await ref
                      .read(subscriptionProvider.notifier)
                      .initiatePayment();
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
