import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../data/models/artisan_model.dart';
import '../data/repositories/search_repository.dart';

class SearchState {
  final List<ArtisanModel> results;
  final bool isLoading;
  final String? error;
  final String? query;
  final String? categoryId;
  final double? radius;
  final String? sortBy;
  final bool availableOnly;
  final int page;
  final bool hasMore;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query,
    this.categoryId,
    this.radius,
    this.sortBy,
    this.availableOnly = false,
    this.page = 1,
    this.hasMore = true,
  });

  SearchState copyWith({
    List<ArtisanModel>? results,
    bool? isLoading,
    String? error,
    String? query,
    String? categoryId,
    double? radius,
    String? sortBy,
    bool? availableOnly,
    int? page,
    bool? hasMore,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      radius: radius ?? this.radius,
      sortBy: sortBy ?? this.sortBy,
      availableOnly: availableOnly ?? this.availableOnly,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repo = SearchRepository();

  SearchNotifier() : super(const SearchState());

  Future<void> search({
    double? latitude,
    double? longitude,
    double? radius,
    String? categoryId,
    String? query,
    String? sortBy,
    bool? availableOnly,
  }) async {
    state = SearchState(
      isLoading: true,
      query: query,
      categoryId: categoryId,
      radius: radius,
      sortBy: sortBy,
      availableOnly: availableOnly ?? false,
    );

    try {
      final results = await _repo.searchArtisans(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        categoryId: categoryId,
        query: query,
        sortBy: sortBy,
        availableOnly: availableOnly,
        page: 1,
      );
      state = state.copyWith(
        results: results,
        isLoading: false,
        page: 1,
        hasMore: results.length >= AppConfig.defaultPageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore({
    double? latitude,
    double? longitude,
  }) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final results = await _repo.searchArtisans(
        latitude: latitude,
        longitude: longitude,
        radius: state.radius,
        categoryId: state.categoryId,
        query: state.query,
        sortBy: state.sortBy,
        availableOnly: state.availableOnly ? true : null,
        page: nextPage,
      );
      state = state.copyWith(
        results: [...state.results, ...results],
        isLoading: false,
        page: nextPage,
        hasMore: results.length >= AppConfig.defaultPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}
