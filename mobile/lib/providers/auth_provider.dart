import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final ApiClient _api = ApiClient();

  @override
  AuthState build() {
    // Check initial auth state asynchronously
    Future.microtask(() => checkAuth());
    return AuthState(isAuthenticated: false, isLoading: true);
  }

  Future<void> checkAuth() async {
    final hasToken = await _api.hasToken();
    if (!hasToken) {
      state = AuthState(isAuthenticated: false, isLoading: false);
      return;
    }

    try {
      final res = await _api.dio.get(ApiEndpoints.me);
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: res.data as Map<String, dynamic>?,
      );
    } catch (_) {
      // If offline, keep authenticated state to allow offline-first browsing
      state = AuthState(isAuthenticated: true, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final formData = FormData.fromMap({
        'username': email.trim(),
        'password': password,
      });

      final res = await _api.dio.post(
        ApiEndpoints.login,
        data: formData,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final token = res.data['access_token'] as String;
      final user = res.data['user'] as Map<String, dynamic>?;

      await _api.setToken(token);
      state = AuthState(isAuthenticated: true, isLoading: false, user: user);
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Erreur de connexion';
      state = state.copyWith(isLoading: false, error: detail.toString());
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Impossible de joindre le serveur');
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String role = 'employee',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.dio.post(
        ApiEndpoints.register,
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          'role': role,
        },
      );

      final token = res.data['access_token'] as String;
      final user = res.data['user'] as Map<String, dynamic>?;

      await _api.setToken(token);
      state = AuthState(isAuthenticated: true, isLoading: false, user: user);
      return true;
    } on DioException catch (e) {
      final detail =
          e.response?.data?['detail'] ?? 'Erreur lors de la création du compte';
      state = state.copyWith(isLoading: false, error: detail.toString());
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de joindre le serveur',
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.dio.put(
        ApiEndpoints.me,
        data: {
          if (fullName != null) 'full_name': fullName.trim(),
          if (email != null) 'email': email.trim(),
          if (phone != null) 'phone': phone.trim(),
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      state = state.copyWith(
        isLoading: false,
        user: res.data as Map<String, dynamic>?,
      );
      return true;
    } on DioException catch (e) {
      final detail =
          e.response?.data?['detail'] ?? 'Erreur lors de la mise à jour';
      state = state.copyWith(isLoading: false, error: detail.toString());
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de joindre le serveur',
      );
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTeamUsers() async {
    try {
      final res = await _api.dio.get(ApiEndpoints.users);
      final list = res.data as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> createTeamMember({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      await _api.dio.post(
        ApiEndpoints.users,
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
          'role': role,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
