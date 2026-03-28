import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/artisan_model.dart';
import '../data/models/review_model.dart';
import '../data/models/portfolio_model.dart';
import '../data/repositories/artisan_repository.dart';

class ArtisanDetailState {
  final ArtisanModel? artisan;
  final List<ReviewModel> reviews;
  final List<PortfolioModel> portfolio;
  final bool isLoading;
  final String? error;

  const ArtisanDetailState({
    this.artisan,
    this.reviews = const [],
    this.portfolio = const [],
    this.isLoading = false,
    this.error,
  });

  ArtisanDetailState copyWith({
    ArtisanModel? artisan,
    List<ReviewModel>? reviews,
    List<PortfolioModel>? portfolio,
    bool? isLoading,
    String? error,
  }) {
    return ArtisanDetailState(
      artisan: artisan ?? this.artisan,
      reviews: reviews ?? this.reviews,
      portfolio: portfolio ?? this.portfolio,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final artisanDetailProvider =
    StateNotifierProvider<ArtisanDetailNotifier, ArtisanDetailState>((ref) {
  return ArtisanDetailNotifier();
});

class ArtisanDetailNotifier extends StateNotifier<ArtisanDetailState> {
  final ArtisanRepository _repo = ArtisanRepository();

  ArtisanDetailNotifier() : super(const ArtisanDetailState());

  Future<void> loadArtisan(String userId) async {
    state = const ArtisanDetailState(isLoading: true);
    try {
      final artisan = await _repo.getArtisan(userId);
      state = state.copyWith(artisan: artisan, isLoading: false);
      // Load reviews and portfolio in parallel
      await Future.wait([
        _loadReviews(artisan.id),
        _loadPortfolio(artisan.id),
      ]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadReviews(String artisanId) async {
    try {
      final reviews = await _repo.getReviews(artisanId);
      state = state.copyWith(reviews: reviews);
    } catch (_) {}
  }

  Future<void> _loadPortfolio(String artisanId) async {
    try {
      final portfolio = await _repo.getPortfolio(artisanId);
      state = state.copyWith(portfolio: portfolio);
    } catch (_) {}
  }

  Future<bool> submitReview({
    required String artisanId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _repo.submitReview(
          artisanId: artisanId, rating: rating, comment: comment);
      await _loadReviews(artisanId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
