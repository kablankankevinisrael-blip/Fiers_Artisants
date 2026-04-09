import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/app_config.dart';
import '../../providers/chat_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/analytics_repository.dart';
import '../common/rating_stars.dart';
import '../common/badge_verified.dart';
import '../common/skeleton_loader.dart';
import '../common/app_button.dart';

class ArtisanProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ArtisanProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ArtisanProfileScreen> createState() =>
      _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState
    extends ConsumerState<ArtisanProfileScreen> {
  bool _isOpeningChat = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(artisanDetailProvider.notifier).loadArtisan(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(artisanDetailProvider);
    final artisan = state.artisan;

    if (state.isLoading || artisan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SkeletonLoader(width: 80, height: 80, borderRadius: 40),
            const SizedBox(height: 16),
            const SkeletonLoader(width: 160, height: 20),
            const SizedBox(height: 8),
            const SkeletonLoader(width: 120, height: 14),
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar with profile
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.black26,
                        child: artisan.profilePhotoUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: artisan.profilePhotoUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                '${artisan.firstName[0]}${artisan.lastName[0]}'
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artisan.fullName,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profession + badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artisan.profession,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (artisan.isVerified)
                        const BadgeVerified(type: BadgeType.verified),
                      if (artisan.isCertified) ...[
                        const SizedBox(width: 4),
                        const BadgeVerified(type: BadgeType.certified),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating + experience
                  Row(
                    children: [
                      RatingStars(rating: artisan.averageRating),
                      const SizedBox(width: 8),
                      Text(
                        '${Formatters.rating(artisan.averageRating)} (${artisan.totalReviews})',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (artisan.experienceYears > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'artisan.experience'.tr(
                          namedArgs: {'years': '${artisan.experienceYears}'}),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${artisan.commune}, ${artisan.city}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (artisan.description != null) ...[
                    const SizedBox(height: 16),
                    Text('artisan.about'.tr(),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(artisan.description!,
                        style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 24),

                  // Contact buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'artisan.contact.chat'.tr(),
                          icon: Icons.chat_bubble_outline,
                          isLoading: _isOpeningChat,
                          onPressed: () => _openChatWithArtisan(
                            participantUserId: artisan.userId,
                            participantName: artisan.fullName,
                            participantAvatarUrl: artisan.profilePhotoUrl,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ContactIcon(
                        icon: Icons.phone_outlined,
                        onTap: () => _launchPhone(artisan.phone),
                      ),
                      const SizedBox(width: 8),
                      _ContactIcon(
                        icon: Icons.message_outlined, // WhatsApp
                        onTap: () => _launchWhatsApp(artisan.phone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Portfolio section
                  if (state.portfolio.isNotEmpty) ...[
                    Text('artisan.portfolio'.tr(),
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.portfolio.length,
                        itemBuilder: (ctx, i) {
                          final item = state.portfolio[i];
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusMedium),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.imageUrls.isNotEmpty)
                                  Hero(
                                    tag: 'portfolio_${item.id}',
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: CachedNetworkImage(
                                        imageUrl: item.imageUrls.first,
                                        width: 200,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      if (item.price != null)
                                        Text(Formatters.fcfa(item.price!),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: theme
                                                        .colorScheme.primary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('artisan.reviews'.tr(),
                          style: theme.textTheme.headlineMedium),
                      TextButton(
                        onPressed: () =>
                            context.push('/client/review/${artisan.id}'),
                        child: Text('review.leave'.tr()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.reviews.isEmpty)
                    Text('review.empty'.tr(),
                        style: theme.textTheme.bodySmall)
                  else
                    ...state.reviews.take(5).map((review) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      review.clientName ?? 'Client',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  RatingStars(
                                      rating: review.rating.toDouble(),
                                      size: 14),
                                ],
                              ),
                              if (review.comment != null) ...[
                                const SizedBox(height: 8),
                                Text(review.comment!,
                                    style: theme.textTheme.bodyMedium),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                Formatters.relativeDate(review.createdAt),
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final AnalyticsRepository _analytics = AnalyticsRepository();

  Future<void> _launchPhone(String phone) async {
    _analytics.logEvent(
      action: 'CONTACT_CLICK',
      targetId: widget.userId,
      metadata: {'method': 'phone'},
    );
    final uri = Uri.parse('tel:${AppConfig.phonePrefix}$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    _analytics.logEvent(
      action: 'CONTACT_CLICK',
      targetId: widget.userId,
      metadata: {'method': 'whatsapp'},
    );
    final uri = Uri.parse(
        'https://wa.me/${AppConfig.phonePrefix}$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openChatWithArtisan({
    required String participantUserId,
    required String participantName,
    String? participantAvatarUrl,
  }) async {
    if (_isOpeningChat) return;
    setState(() => _isOpeningChat = true);
    try {
      final convo =
          await ref.read(chatProvider.notifier).createConversation(participantUserId);
      if (!mounted) return;
      final queryParams = <String, String>{'name': participantName};
      final avatar = participantAvatarUrl?.trim();
      if (avatar != null && avatar.isNotEmpty) {
        queryParams['avatar'] = avatar;
      }
      final query = Uri(queryParameters: queryParams).query;
      context.push('/chat/${convo.id}?$query');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de demarrer la conversation.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningChat = false);
      }
    }
  }
}

class _ContactIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ContactIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
