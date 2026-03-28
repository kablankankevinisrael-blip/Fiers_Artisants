import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/artisan_model.dart';
import '../data/repositories/search_repository.dart';

class SearchState {
  final List<ArtisanModel> results;
  final bool isLoading;
  final String? error;
  final String? query;
  final String? categoryId;
  final double? radius;
  final int page;
  final bool hasMore;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query,
    this.categoryId,
    this.radius,
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
  }) async {
    state = SearchState(
      isLoading: true,
      query: query,
      categoryId: categoryId,
      radius: radius,
    );

    try {
      final results = await _repo.searchArtisans(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        categoryId: categoryId,
        query: query,
        page: 1,
      );
      state = state.copyWith(
        results: results,
        isLoading: false,
        page: 1,
        hasMore: results.length >= 20,
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
        page: nextPage,
      );
      state = state.copyWith(
        results: [...state.results, ...results],
        isLoading: false,
        page: nextPage,
        hasMore: results.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}
