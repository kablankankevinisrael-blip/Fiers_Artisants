import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/subscription_provider.dart';
import '../common/app_button.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(subscriptionProvider.notifier).loadStatus(),
    );
  }

  Future<void> _handlePayment() async {
    final messenger = ScaffoldMessenger.of(context);
    final data =
        await ref.read(subscriptionProvider.notifier).initiatePayment();
    if (!mounted) return;

    final checkoutUrl = data?['checkout_url']?.toString();
    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      final uri = Uri.parse(checkoutUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (!mounted) return;

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('subscription.error_open_wave'.tr())),
        );
      }
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('subscription.error_payment'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: Text('subscription.title'.tr())),
      body: subState.isLoading && subState.subscription == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
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
                          style: const TextStyle(
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
                  if (subState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        subState.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  if (subState.subscription?.isActive != true)
                    AppButton(
                      text: 'subscription.pay'.tr(),
                      icon: Icons.payment,
                      isLoading: subState.isLoading,
                      onPressed: _handlePayment,
                    )
                  else
                    AppButton(
                      text: 'subscription.renew'.tr(),
                      isOutlined: true,
                      isLoading: subState.isLoading,
                      onPressed: _handlePayment,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
