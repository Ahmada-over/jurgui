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

  Future<void> logout() async {
    await _api.clearToken();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
