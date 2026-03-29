import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/artisan_model.dart';
import '../models/review_model.dart';
import '../models/portfolio_model.dart';

class ArtisanRepository {
  final ApiClient _api = ApiClient();

  Future<ArtisanModel> getArtisan(String userId) async {
    final response = await _api.get(ApiEndpoints.artisanById(userId));
    return ArtisanModel.fromJson(response.data);
  }

  Future<List<ReviewModel>> getReviews(String artisanId, {int page = 1}) async {
    final response = await _api.get(
      ApiEndpoints.reviewsByArtisan(artisanId),
      queryParameters: {'page': page},
    );
    final list = response.data is List ? response.data : response.data['data'] ?? [];
    return (list as List).map((e) => ReviewModel.fromJson(e)).toList();
  }

  Future<void> submitReview({
    required String artisanId,
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'artisan_id': artisanId,
      'rating': rating,
    };
    if (comment != null) body['comment'] = comment;

    await _api.post(ApiEndpoints.reviews, data: body);
  }

  Future<List<PortfolioModel>> getPortfolio(String artisanId) async {
    final response = await _api.get(ApiEndpoints.portfolioByArtisan(artisanId));
    final list = response.data is List ? response.data : response.data['data'] ?? [];
    return (list as List).map((e) => PortfolioModel.fromJson(e)).toList();
  }

  Future<void> addPortfolioItem({
    required String title,
    String? description,
    double? price,
    required List<String> imageUrls,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'imageUrls': imageUrls,
    };
    if (description != null) body['description'] = description;
    if (price != null) body['priceFcfa'] = price.toInt();

    await _api.post(ApiEndpoints.portfolio, data: body);
  }
}
