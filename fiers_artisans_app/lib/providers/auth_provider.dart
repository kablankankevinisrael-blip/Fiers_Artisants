import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

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
      } catch (e) {
        if (_isOtpRequired(e)) {
          debugPrint('[Auth] checkAuth: 403 OTP_REQUIRED from backend');
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
        debugPrint('[Auth] ⚠️ role is empty — check backend response structure');
      }
      final userId = userMap['id']?.toString() ?? '';
      await SecureStorage.saveUserInfo(userId: userId, role: role.toLowerCase());

      final user = UserModel.fromJson(userMap);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      // Détecter 403 OTP_REQUIRED
      if (_isOtpRequired(e)) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          otpRequired: true,
          otpPhone: phone,
        );
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractError(e),
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
      await SecureStorage.saveUserInfo(userId: userId, role: role.toLowerCase());

      final user = UserModel.fromJson(userMap);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractError(e),
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
      await SecureStorage.saveUserInfo(userId: userId, role: role.toLowerCase());

      final user = UserModel.fromJson(userMap);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _extractError(e),
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
    await SecureStorage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Détecte une réponse 403 OTP_REQUIRED du backend.
  /// Le GlobalExceptionFilter peut renvoyer message comme String ou List.
  bool _isOtpRequired(dynamic e) {
    if (e is DioException && e.response?.statusCode == 403) {
      var data = e.response?.data;
      if (data is Map<String, dynamic>) {
        // Unwrap enveloppe {statusCode, data, timestamp} si présente
        if (data.containsKey('data') && data.containsKey('statusCode')) {
          data = data['data'];
        }
        if (data is Map) {
          if (_messageContains(data['message'], 'OTP_REQUIRED')) return true;
          // Fallback: error == 'Forbidden' + message contient OTP_REQUIRED
          if (data['error'] == 'Forbidden' &&
              _messageContains(data['message'], 'OTP_REQUIRED')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Vérifie si [message] (String ou List) contient la valeur cible.
  bool _messageContains(dynamic message, String target) {
    if (message is String) return message == target;
    if (message is List) return message.any((m) => m.toString() == target);
    return false;
  }

  /// Extrait access_token et refresh_token depuis la réponse backend (déjà unwrappée).
  (String, String) _extractTokens(Map<String, dynamic> data) {
    final access = data['access_token']?.toString() ??
        data['accessToken']?.toString() ??
        '';
    final refresh = data['refresh_token']?.toString() ??
        data['refreshToken']?.toString() ??
        '';
    if (access.isEmpty) {
      debugPrint('[Auth] ⚠️ access_token is empty in response: ${data.keys}');
    }
    return (access, refresh);
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      // Extraire le message du backend (peut être dans l'enveloppe ou direct)
      var data = e.response?.data;
      if (data is Map<String, dynamic>) {
        // Unwrap l'enveloppe si présente
        if (data.containsKey('data') && data.containsKey('statusCode')) {
          data = data['data'];
        }
        if (data is Map<String, dynamic>) {
          final message = data['message'];
          if (message is List) return message.join(', ');
          if (message is String) return message;
        }
      }
      // Messages réseau détaillés
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          return 'Le serveur met trop de temps à répondre. '
              'Vérifiez que le backend est démarré sur le port 3000.';
        case DioExceptionType.receiveTimeout:
          return 'Réponse du serveur trop lente. Réessayez.';
        case DioExceptionType.connectionError:
          final msg = e.error?.toString() ?? '';
          if (msg.contains('Connection refused') ||
              msg.contains('ECONNREFUSED')) {
            return 'Serveur indisponible (connexion refusée). '
                'Vérifiez que le backend et les services Docker sont lancés.';
          }
          if (msg.contains('Network is unreachable') ||
              msg.contains('SocketException')) {
            return 'Réseau inaccessible. Vérifiez votre Wi-Fi '
                'et que le téléphone est sur le même réseau que le PC.';
          }
          return 'Impossible de joindre le serveur. '
              'Vérifiez votre connexion réseau.';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 401) return 'Identifiants incorrects.';
          if (code == 403) return 'Accès refusé. Veuillez vérifier votre téléphone.';
          if (code == 409) return 'Ce compte existe déjà.';
          if (code == 400) return 'Données invalides. Vérifiez les champs.';
          if (code == 500) return 'Erreur interne du serveur. Réessayez.';
          return 'Erreur serveur ($code).';
        default:
          return e.message ?? 'Erreur réseau inattendue.';
      }
    }
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'Une erreur est survenue.';
  }
}
