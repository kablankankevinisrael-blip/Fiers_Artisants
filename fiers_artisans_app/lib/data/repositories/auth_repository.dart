import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _api.post(
      ApiEndpoints.login,
      data: {'phone': phone, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> registerArtisan({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String profession,
    required String city,
    required String commune,
    String? email,
    String? description,
    int? experienceYears,
    String? categoryId,
  }) async {
    final response = await _api.post(
      ApiEndpoints.registerArtisan,
      data: {
        'phone': phone,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'profession': profession,
        'city': city,
        'commune': commune,
        'email': ?email,
        'description': ?description,
        'experienceYears': ?experienceYears,
        'categoryId': ?categoryId,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> registerClient({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
    required String commune,
    String? email,
  }) async {
    final response = await _api.post(
      ApiEndpoints.registerClient,
      data: {
        'phone': phone,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'commune': commune,
        'email': ?email,
      },
    );
    return response.data;
  }

  Future<void> sendOtp(String phone) async {
    await _api.post(ApiEndpoints.sendOtp, data: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _api.post(
      ApiEndpoints.verifyOtp,
      data: {'phone': phone, 'code': code},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _api.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    return response.data;
  }

  Future<UserModel> getProfile() async {
    final response = await _api.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data);
  }
}
