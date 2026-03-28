import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier();
});

class CategoriesState {
  final List<CategoryModel> categories;
  final bool isLoading;

  const CategoriesState({this.categories = const [], this.isLoading = false});
}

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  CategoriesNotifier() : super(const CategoriesState());

  Future<void> load() async {
    if (state.categories.isNotEmpty) return; // cached
    state = const CategoriesState(isLoading: true);
    try {
      final response = await ApiClient().get(ApiEndpoints.categories);
      final list =
          response.data is List ? response.data : response.data['data'] ?? [];
      final categories =
          (list as List).map((e) => CategoryModel.fromJson(e)).toList();
      state = CategoriesState(categories: categories);
    } catch (_) {
      state = const CategoriesState();
    }
  }
}
