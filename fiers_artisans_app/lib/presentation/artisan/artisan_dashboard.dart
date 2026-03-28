import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';

class ArtisanDashboard extends ConsumerStatefulWidget {
  const ArtisanDashboard({super.key});

  @override
  ConsumerState<ArtisanDashboard> createState() => _ArtisanDashboardState();
}

class _ArtisanDashboardState extends ConsumerState<ArtisanDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(subscriptionProvider.notifier).loadStatus());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            await ref.read(subscriptionProvider.notifier).loadStatus();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.greeting'.tr(namedArgs: {
                          'name': user?.firstName ?? ''
                        }),
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tableau de bord artisan',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Subscription status card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'subscription.title'.tr(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subState.subscription?.isActive == true
                                  ? 'subscription.expires_in'.tr(namedArgs: {
                                      'days':
                                          '${subState.subscription!.daysRemaining}'
                                    })
                                  : 'subscription.expired'.tr(),
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      if (subState.subscription?.isActive != true)
                        ElevatedButton(
                          onPressed: () =>
                              context.push('/artisan/subscription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: AppTheme.gold,
                          ),
                          child: Text('subscription.pay'.tr()),
                        ),
                    ],
                  ),
                ),
              ),

              // Quick actions grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _DashboardTile(
                        icon: Icons.photo_library_outlined,
                        label: 'portfolio.title'.tr(),
                        onTap: () => context.push('/artisan/portfolio'),
                      ),
                      _DashboardTile(
                        icon: Icons.verified_outlined,
                        label: 'artisan.verification.title'.tr(),
                        onTap: () => context.push('/artisan/verification'),
                      ),
                      _DashboardTile(
                        icon: Icons.settings_outlined,
                        label: 'settings.title'.tr(),
                        onTap: () => context.push('/settings'),
                      ),
                      _DashboardTile(
                        icon: Icons.star_outline_rounded,
                        label: 'review.title'.tr(),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
