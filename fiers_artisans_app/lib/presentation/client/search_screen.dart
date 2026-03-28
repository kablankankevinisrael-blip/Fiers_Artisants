import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/app_config.dart';
import '../../providers/search_provider.dart';
import '../../providers/categories_provider.dart';
import '../common/app_text_field.dart';
import '../common/artisan_card.dart';
import '../common/category_chip.dart';
import '../common/skeleton_loader.dart';
import '../common/empty_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialParams;
  const SearchScreen({super.key, this.initialParams});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategoryId;
  double _radius = AppConfig.defaultSearchRadius;
  double? _latitude;
  double? _longitude;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoriesProvider.notifier).load();
      _initLocation();

      // Handle initial params
      if (widget.initialParams != null) {
        final cat = widget.initialParams!['categoryId'] as String?;
        if (cat != null) {
          setState(() => _selectedCategoryId = cat);
        }
      }
    });
  }

  Future<void> _initLocation() async {
    setState(() => _locationLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    } catch (_) {
      // Default: Abidjan
      _latitude = 5.3600;
      _longitude = -4.0083;
    }
    setState(() => _locationLoading = false);
    _search();
  }

  void _search() {
    ref.read(searchProvider.notifier).search(
          latitude: _latitude,
          longitude: _longitude,
          radius: _radius,
          categoryId: _selectedCategoryId,
          query: _searchCtrl.text.trim().isNotEmpty
              ? _searchCtrl.text.trim()
              : null,
        );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    final catState = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('search.title'.tr())),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              controller: _searchCtrl,
              hint: 'search.placeholder'.tr(),
              prefixIcon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              suffix: IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: _showFilters,
              ),
            ),
          ),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: catState.categories.length,
              itemBuilder: (context, index) {
                final cat = catState.categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: cat.name,
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId =
                            _selectedCategoryId == cat.id ? null : cat.id;
                      });
                      _search();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Radius indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'search.radius'.tr(namedArgs: {
                    'km': _radius.toStringAsFixed(0)
                  }),
                  style: theme.textTheme.bodySmall,
                ),
                if (searchState.results.isNotEmpty)
                  Text(
                    '  •  ${searchState.results.length} résultat(s)',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _locationLoading || searchState.isLoading
                ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SkeletonLoader.artisanCard(),
                    ),
                  )
                : searchState.results.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'search.no_results'.tr(),
                        actionLabel: 'common.retry'.tr(),
                        onAction: _search,
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: searchState.results.length,
                        itemBuilder: (context, index) {
                          final artisan = searchState.results[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ArtisanCard(
                              artisan: artisan,
                              onTap: () => context.push(
                                '/client/artisan/${artisan.userId}',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('search.filter'.tr(),
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text(
              'search.radius'.tr(
                  namedArgs: {'km': _radius.toStringAsFixed(0)}),
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            Slider(
              value: _radius,
              min: 1,
              max: AppConfig.maxSearchRadius,
              divisions: 49,
              label: '${_radius.toStringAsFixed(0)} km',
              onChanged: (v) => setState(() => _radius = v),
              onChangeEnd: (_) {
                Navigator.pop(ctx);
                _search();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
