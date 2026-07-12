import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/failure.dart';
import '../../../core/network/unauthorized_handler.dart';
import '../data/auth_repository.dart';
import '../domain/models/user.dart';
import '../../../shared/models/user_role.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
}

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.user,
  });

  final AuthStatus status;
  final AuthUser? user;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  UserRole? get role => user?.role;
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  AuthRepository get _authRepository => getIt<AuthRepository>();

  @override
  AuthSessionState build() {
    return const AuthSessionState(status: AuthStatus.unknown);
  }

  Future<void> restoreSession() async {
    try {
      if (!await _authRepository.hasStoredSession()) {
        markUnauthenticated();
        return;
      }

      var result = await _authRepository.fetchCurrentUser();

      if (_shouldRetryAfterRefresh(result)) {
        final refreshed = await _authRepository.refreshTokens();
        if (refreshed) {
          result = await _authRepository.fetchCurrentUser();
        }
      }

      if (result.isFailure || result.data == null) {
        await _authRepository.logout();
        markUnauthenticated();
        return;
      }

      setAuthenticated(result.data!);
    } catch (_) {
      await _authRepository.logout();
      markUnauthenticated();
    }
  }

  void setAuthenticated(User user) {
    UnauthorizedHandler.reset();
    state = AuthSessionState(
      status: AuthStatus.authenticated,
      user: _toAuthUser(user),
    );
  }

  Future<Failure?> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final result = await _authRepository.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    if (result.isFailure || result.data == null) {
      return result.failure ??
          const Failure(message: 'Unable to sign in. Please try again.');
    }

    setAuthenticated(result.data!);
    return null;
  }

  Future<void> signOut() async {
    await _authRepository.logout();
    markUnauthenticated();
  }

  void markUnauthenticated() {
    UnauthorizedHandler.reset();
    state = const AuthSessionState(status: AuthStatus.unauthenticated);
  }

  bool _shouldRetryAfterRefresh(ApiResult<User> result) {
    if (!result.isFailure) {
      return false;
    }

    return result.failure?.type == FailureType.unauthorized;
  }

  AuthUser _toAuthUser(User user) {
    return AuthUser(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    );
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
  AuthSessionNotifier.new,
);
