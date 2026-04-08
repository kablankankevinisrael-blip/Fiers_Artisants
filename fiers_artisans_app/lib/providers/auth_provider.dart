import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/error_mapper.dart';
import '../core/storage/secure_storage.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../services/chat_realtime_service.dart';
import '../services/push_notification_service.dart';

// Auth state
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool otpRequired;
  final String? otpPhone;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.otpRequired = false,
    this.otpPhone,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? otpRequired,
    String? otpPhone,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      otpRequired: otpRequired ?? false,
      otpPhone: otpPhone,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo = AuthRepository();

  AuthNotifier() : super(const AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final isLoggedIn = await SecureStorage.isLoggedIn();
    if (isLoggedIn) {
      try {
        final user = await _repo.getProfile();
        if (!user.isPhoneVerified) {
          debugPrint('[Auth] checkAuth: phone not verified → OTP required');
          await SecureStorage.clearAll();
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }
        state = AuthState(status: AuthStatus.authenticated, user: user);
        PushNotificationService().initialize().catchError((_) {});
        _connectRealtime(user.id);
      } catch (e) {
        final appError = mapException(e);
        if (appError.isOtpRequired) {
          debugPrint('[Auth] checkAuth: OTP required (code=${appError.code})');
        }
        await SecureStorage.clearAll();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final data = await _repo.login(phone: phone, password: password);
      final tokens = _extractTokens(data);
      await SecureStorage.saveTokens(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
      );
      final userMap = data['user'] as Map<String, dynamic>? ?? {};
      final role = (userMap['role'] ?? '').toString();
      debugPrint('[Auth] login role from backend: "$role"');
      if (role.isEmpty) {
        debugPrint(
          '[Auth] ⚠️ role is empty — check backend response structure',
        );
      }
      final userId = userMap['id']?.toString() ?? '';
      await SecureStorage.saveUserInfo(
        userId: userId,
        role: role.toLowerCase(),
      );

      final user = UserModel.fromJson(userMap);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      PushNotificationService().initialize().catchError((_) {});
      _connectRealtime(userId);
      return true;
    } catch (e) {
      final appError = mapException(e);
      debugPrint('[Auth] login error: $appError');

      // Détecter OTP requis via le code stable
      if (appError.isOtpRequired) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          otpRequired: true,
          otpPhone: phone,
        );
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: appError.userMessage,
      );
      return false;
    }
  }

  Future<bool> registerArtisan({
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
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final data = await _repo.registerArtisan(
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        profession: profession,
        city: city,
        commune: commune,
        email: email,
        description: description,
        experienceYears: experienceYears,
        categoryId: categoryId,
      );
      final tokens = _extractTokens(data);
      await SecureStorage.saveTokens(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
      );
      final userMap = data['user'] as Map<String, dynamic>? ?? {};
      final role = (userMap['role'] ?? 'ARTISAN').toString();
      debugPrint('[Auth] registerArtisan role from backend: "$role"');
      final userId = userMap['id']?.toString() ?? '';
      await SecureStorage.saveUserInfo(
        userId: userId,
        role: role.toLowerCase(),
      );

      final user = UserModel.fromJson(userMap);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      PushNotificationService().initialize().catchError((_) {});
      _connectRealtime(userId);
      return true;
    } catch (e) {
      final appError = mapException(e);
      debugPrint('[Auth] registerArtisan error: $appError');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: appError.userMessage,
      );
      return false;
    }
  }

  Future<bool> registerClient({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
    required String commune,
    String? email,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final data = await _repo.registerClient(
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        city: city,
        commune: commune,
        email: email,
      );
      final tokens = _extractTokens(data);
      await SecureStorage.saveTokens(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
      );
      final userMap = data['user'] as Map<String, dynamic>? ?? {};
      final role = (userMap['role'] ?? 'CLIENT').toString();
      debugPrint('[Auth] registerClient role from backend: "$role"');
      final userId = userMap['id']?.toString() ?? '';
      await SecureStorage.saveUserInfo(
        userId: userId,
        role: role.toLowerCase(),
      );

      final user = UserModel.fromJson(userMap);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      PushNotificationService().initialize().catchError((_) {});
      _connectRealtime(userId);
      return true;
    } catch (e) {
      final appError = mapException(e);
      debugPrint('[Auth] registerClient error: $appError');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: appError.userMessage,
      );
      return false;
    }
  }

  Future<void> sendOtp(String phone) async {
    await _repo.sendOtp(phone);
  }

  Future<bool> verifyOtp({required String phone, required String code}) async {
    try {
      await _repo.verifyOtp(phone: phone, code: code);
      if (state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(isPhoneVerified: true),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    ChatRealtimeService().disconnect();
    await SecureStorage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _connectRealtime(String userId) {
    if (userId.isEmpty) return;
    ChatRealtimeService().connect(userId: userId).catchError((_) {});
  }

  /// Extrait access_token et refresh_token depuis la réponse backend (déjà unwrappée).
  (String, String) _extractTokens(Map<String, dynamic> data) {
    final access =
        data['access_token']?.toString() ??
        data['accessToken']?.toString() ??
        '';
    final refresh =
        data['refresh_token']?.toString() ??
        data['refreshToken']?.toString() ??
        '';
    if (access.isEmpty) {
      debugPrint('[Auth] ⚠️ access_token is empty in response: ${data.keys}');
    }
    return (access, refresh);
  }
}
