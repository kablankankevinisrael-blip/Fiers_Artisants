import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/verification_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/push_notification_service.dart';

class ArtisanDashboard extends ConsumerStatefulWidget {
  const ArtisanDashboard({super.key});

  @override
  ConsumerState<ArtisanDashboard> createState() => _ArtisanDashboardState();
}

class _ArtisanDashboardState extends ConsumerState<ArtisanDashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _loadAvailability();
    Future.microtask(() {
      ref.read(subscriptionProvider.notifier).loadStatus();
      ref.read(chatProvider.notifier).loadConversations();
      ref.read(verificationProvider.notifier).refresh();
    });

    // Wire FCM verification push → provider refresh
    PushNotificationService().onVerificationUpdate = () {
      ref.read(verificationProvider.notifier).refresh();
    };
  }

  Future<void> _loadAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isAvailable = prefs.getBool('artisan_available') ?? true);
  }

  Future<void> _toggleAvailability(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('artisan_available', val);
    setState(() => _isAvailable = val);
    // TODO: Sync availability with backend when endpoint is ready
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(subscriptionProvider.notifier).loadStatus(),
      ref.read(chatProvider.notifier).loadConversations(),
      ref.read(verificationProvider.notifier).refresh(),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(verificationProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    PushNotificationService().onVerificationUpdate = null;
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final subState = ref.watch(subscriptionProvider);
    final chatState = ref.watch(chatProvider);
    final vState = ref.watch(verificationProvider);
    final isDark = theme.brightness == Brightness.dark;

    final unreadMessages = chatState.conversations
        .fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: _onRefresh,
          child: FadeTransition(
            opacity: _fadeIn,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── Header + availability toggle ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
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
                                'dashboard.artisan.subtitle'.tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Switch.adaptive(
                              value: _isAvailable,
                              activeTrackColor: AppTheme.success,
                              onChanged: _toggleAvailability,
                            ),
                            Text(
                              _isAvailable
                                  ? 'artisan.available'.tr()
                                  : 'artisan.unavailable'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _isAvailable
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Account status cards ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _SubscriptionCard(
                      subState: subState,
                      onTap: () => context.push('/artisan/subscription'),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _VerificationCard(
                      vState: vState,
                      onTap: () => context.push('/artisan/verification'),
                    ),
                  ),
                ),

                // ── Performance KPIs ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text(
                      'dashboard.artisan.performance'.tr(),
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.visibility_outlined,
                            value: '--',
                            label: 'dashboard.artisan.profile_views'.tr(),
                            // TODO: Wire to backend analytics endpoint
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.mail_outline_rounded,
                            value: '$unreadMessages',
                            label: 'dashboard.artisan.unread_messages'.tr(),
                            highlight: unreadMessages > 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.star_outline_rounded,
                            value: user != null ? '—' : '--',
                            label: 'dashboard.artisan.avg_rating'.tr(),
                            // TODO: Wire to artisan profile averageRating
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.rate_review_outlined,
                            value: user != null ? '—' : '--',
                            label: 'dashboard.artisan.total_reviews'.tr(),
                            // TODO: Wire to artisan profile totalReviews
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Quick actions ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text(
                      'dashboard.artisan.quick_actions'.tr(),
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _ActionTile(
                          icon: Icons.photo_library_outlined,
                          label: 'portfolio.title'.tr(),
                          color: AppTheme.gold,
                          onTap: () => context.push('/artisan/portfolio'),
                        ),
                        _ActionTile(
                          icon: Icons.verified_outlined,
                          label: 'artisan.verification.title'.tr(),
                          color: AppTheme.warning,
                          onTap: () => context.push('/artisan/verification'),
                        ),
                        _ActionTile(
                          icon: Icons.credit_card_outlined,
                          label: 'subscription.title'.tr(),
                          color: AppTheme.success,
                          onTap: () => context.push('/artisan/subscription'),
                        ),
                        _ActionTile(
                          icon: Icons.settings_outlined,
                          label: 'settings.title'.tr(),
                          color: isDark
                              ? const Color(0xFF9E9EA8)
                              : const Color(0xFF6B6B75),
                          onTap: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Recent conversations ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'dashboard.artisan.inbox'.tr(),
                          style: theme.textTheme.headlineMedium,
                        ),
                        if (chatState.conversations.isNotEmpty)
                          TextButton(
                            onPressed: () => context.push('/chat'),
                            child: Text('home.see_all'.tr()),
                          ),
                      ],
                    ),
                  ),
                ),

                if (chatState.conversations.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 40,
                                color: theme.textTheme.bodySmall?.color),
                            const SizedBox(height: 12),
                            Text(
                              'chat.empty'.tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= 3) return null;
                        final convo = chatState.conversations[index];
                        return _ConversationTile(
                          name: convo.participantName,
                          lastMessage: convo.lastMessage ?? '',
                          unread: convo.unreadCount,
                          onTap: () =>
                              context.push('/chat/${convo.id}'),
                        );
                      },
                      childCount: chatState.conversations.length.clamp(0, 3),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// COMPONENTS
// ═══════════════════════════════════════════════════════════════════

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionState subState;
  final VoidCallback onTap;

  const _SubscriptionCard({required this.subState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = subState.subscription;
    final isActive = sub?.isActive == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.goldGradient : null,
          color: isActive ? null : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? null : Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.black.withValues(alpha: 0.15)
                    : AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive
                    ? Icons.workspace_premium_rounded
                    : Icons.warning_amber_rounded,
                color: isActive ? Colors.black : AppTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'subscription.title'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isActive ? Colors.black : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'subscription.expires_in'.tr(namedArgs: {
                            'days': '${sub!.daysRemaining}'
                          })
                        : 'subscription.expired'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? Colors.black87 : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
            if (!isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'subscription.pay'.tr(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final VerificationState vState;
  final VoidCallback onTap;

  const _VerificationCard({required this.vState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = vState.dashboardLabel;

    final (Color statusColor, String statusText, IconData statusIcon) =
        switch (label) {
      'VERIFIED' || 'CERTIFIED' => (
          AppTheme.success,
          'artisan.verification.approved'.tr(),
          Icons.check_circle_outline,
        ),
      'PENDING' => (
          AppTheme.warning,
          'artisan.verification.pending'.tr(),
          Icons.schedule_outlined,
        ),
      'REJECTED' => (
          AppTheme.error,
          'artisan.verification.rejected'.tr(),
          Icons.cancel_outlined,
        ),
      _ => (
          theme.textTheme.bodySmall?.color ?? Colors.grey,
          'artisan.verification.not_submitted'.tr(),
          Icons.upload_file_outlined,
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'artisan.verification.title'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 13, color: statusColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppTheme.gold.withValues(alpha: 0.5)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final int unread;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.lastMessage,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (lastMessage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lastMessage,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
