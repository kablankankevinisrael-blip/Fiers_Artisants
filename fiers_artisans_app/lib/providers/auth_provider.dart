import 'package:dio/dio.dart';
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

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
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
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } catch (_) {
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
      await SecureStorage.saveTokens(
        accessToken: data['accessToken'] ?? data['access_token'] ?? '',
        refreshToken: data['refreshToken'] ?? data['refresh_token'] ?? '',
      );
      final userId = data['user']?['id']?.toString() ?? '';
      final role = (data['user']?['role'] ?? 'CLIENT').toString();
      await SecureStorage.saveUserInfo(userId: userId, role: role);

      final user = UserModel.fromJson(data['user'] ?? {});
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
      await SecureStorage.saveTokens(
        accessToken: data['accessToken'] ?? data['access_token'] ?? '',
        refreshToken: data['refreshToken'] ?? data['refresh_token'] ?? '',
      );
      final userId = data['user']?['id']?.toString() ?? '';
      await SecureStorage.saveUserInfo(userId: userId, role: 'artisan');

      final user = UserModel.fromJson(data['user'] ?? {});
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
      await SecureStorage.saveTokens(
        accessToken: data['accessToken'] ?? data['access_token'] ?? '',
        refreshToken: data['refreshToken'] ?? data['refresh_token'] ?? '',
      );
      final userId = data['user']?['id']?.toString() ?? '';
      await SecureStorage.saveUserInfo(userId: userId, role: 'client');

      final user = UserModel.fromJson(data['user'] ?? {});
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

  String _extractError(dynamic e) {
    if (e is DioException) {
      // Extraire le message du backend si disponible
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is List) return message.join(', ');
        if (message is String) return message;
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
