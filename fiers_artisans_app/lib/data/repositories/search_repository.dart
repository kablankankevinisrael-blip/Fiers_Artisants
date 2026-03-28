import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/artisan_model.dart';

class SearchRepository {
  final ApiClient _api = ApiClient();

  Future<List<ArtisanModel>> searchArtisans({
    double? latitude,
    double? longitude,
    double? radius,
    String? categoryId,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiEndpoints.search,
      queryParameters: {
        'latitude': ?latitude,
        'longitude': ?longitude,
        'radius': ?radius,
        'categoryId': ?categoryId,
        if (query != null && query.isNotEmpty) 'query': query,
        'page': page,
        'limit': limit,
      },
    );
    final list = response.data is List ? response.data : response.data['data'] ?? [];
    return (list as List).map((e) => ArtisanModel.fromJson(e)).toList();
  }
}
