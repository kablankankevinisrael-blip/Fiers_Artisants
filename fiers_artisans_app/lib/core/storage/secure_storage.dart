import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';
import 'web_local_storage_stub.dart'
    if (dart.library.html) 'web_local_storage_web.dart'
    as web_storage;

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(
        key: AppConstants.keyAccessToken,
        value: accessToken,
      );
      await _storage.write(
        key: AppConstants.keyRefreshToken,
        value: refreshToken,
      );
    } catch (_) {}

    await web_storage.writeWebLocalStorage(
      AppConstants.keyAccessToken,
      accessToken,
    );
    await web_storage.writeWebLocalStorage(
      AppConstants.keyRefreshToken,
      refreshToken,
    );
  }

  static Future<String?> getAccessToken() async {
    try {
      final value = await _storage.read(key: AppConstants.keyAccessToken);
      if ((value ?? '').isNotEmpty) return value;
    } catch (_) {}
    return web_storage.readWebLocalStorage(AppConstants.keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    try {
      final value = await _storage.read(key: AppConstants.keyRefreshToken);
      if ((value ?? '').isNotEmpty) return value;
    } catch (_) {}
    return web_storage.readWebLocalStorage(AppConstants.keyRefreshToken);
  }

  // User info
  static Future<void> saveUserInfo({
    required String userId,
    required String role,
  }) async {
    try {
      await _storage.write(key: AppConstants.keyUserId, value: userId);
      await _storage.write(key: AppConstants.keyUserRole, value: role);
    } catch (_) {}

    await web_storage.writeWebLocalStorage(AppConstants.keyUserId, userId);
    await web_storage.writeWebLocalStorage(AppConstants.keyUserRole, role);
  }

  static Future<String?> getUserId() async {
    try {
      final value = await _storage.read(key: AppConstants.keyUserId);
      if ((value ?? '').isNotEmpty) return value;
    } catch (_) {}
    return web_storage.readWebLocalStorage(AppConstants.keyUserId);
  }

  static Future<String?> getUserRole() async {
    try {
      final value = await _storage.read(key: AppConstants.keyUserRole);
      if ((value ?? '').isNotEmpty) return value;
    } catch (_) {}
    return web_storage.readWebLocalStorage(AppConstants.keyUserRole);
  }

  // Clear all
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    await web_storage.clearWebLocalStorage();
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
