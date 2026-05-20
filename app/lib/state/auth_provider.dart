import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums/app_enums.dart';

// ── Auth State ────────────────────────────────────────────────

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? token;
  final String? errorMessage;
  final DateTime? createdAt;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userId,
    this.token,
    this.errorMessage,
    this.createdAt,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? token,
    String? errorMessage,
    DateTime? createdAt,
  }) =>
      AuthState(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        token: token ?? this.token,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void setAuthenticated({required String userId, required String token}) {
    state = AuthState(
      status: AuthStatus.authenticated,
      userId: userId,
      token: token,
      createdAt: state.createdAt ?? DateTime.now(),
    );
  }

  void setLoading() {
    state = state.copyWith(status: AuthStatus.loading);
  }

  void setError(String message) {
    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }

  void logout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
