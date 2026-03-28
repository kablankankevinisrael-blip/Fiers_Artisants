import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _storage.write(
        key: AppConstants.keyRefreshToken, value: refreshToken);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.keyAccessToken);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.keyRefreshToken);

  // User info
  static Future<void> saveUserInfo({
    required String userId,
    required String role,
  }) async {
    await _storage.write(key: AppConstants.keyUserId, value: userId);
    await _storage.write(key: AppConstants.keyUserRole, value: role);
  }

  static Future<String?> getUserId() =>
      _storage.read(key: AppConstants.keyUserId);

  static Future<String?> getUserRole() =>
      _storage.read(key: AppConstants.keyUserRole);

  // Clear all
  static Future<void> clearAll() => _storage.deleteAll();

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
