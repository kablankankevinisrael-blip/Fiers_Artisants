import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login({
    required String phone,
    required String pinCode,
  }) async {
    final response = await _api.post(
      ApiEndpoints.login,
      data: {'phone_number': phone, 'pin_code': pinCode},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> registerArtisan({
    required String phone,
    required String pinCode,
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
    final body = <String, dynamic>{
      'phone_number': phone,
      'pin_code': pinCode,
      'first_name': firstName,
      'last_name': lastName,
      'business_name': profession,
      'city': city,
      'commune': commune,
    };
    if (email != null) body['email'] = email;

    final response = await _api.post(
      ApiEndpoints.registerArtisan,
      data: body,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> registerClient({
    required String phone,
    required String pinCode,
    required String firstName,
    required String lastName,
    required String city,
    required String commune,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'phone_number': phone,
      'pin_code': pinCode,
      'first_name': firstName,
      'last_name': lastName,
      'city': city,
      'commune': commune,
    };
    if (email != null) body['email'] = email;

    final response = await _api.post(
      ApiEndpoints.registerClient,
      data: body,
    );
    return response.data;
  }

  Future<void> sendOtp(String phone) async {
    await _api.post(ApiEndpoints.sendOtp, data: {'phone_number': phone});
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _api.post(
      ApiEndpoints.verifyOtp,
      data: {'phone_number': phone, 'code': code},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> setupPin({
    required String phone,
    required String code,
    required String pinCode,
  }) async {
    final response = await _api.post(
      ApiEndpoints.setupPin,
      data: {
        'phone_number': phone,
        'code': code,
        'pin_code': pinCode,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _api.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    return response.data;
  }

  Future<UserModel> getProfile() async {
    final role = await SecureStorage.getUserRole();
    final endpoint = (role ?? '').toUpperCase() == 'ARTISAN'
        ? ApiEndpoints.artisanProfile
        : ApiEndpoints.clientProfile;
    final response = await _api.get(endpoint);
    return UserModel.fromJson(response.data);
  }
}
