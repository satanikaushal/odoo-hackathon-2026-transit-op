import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/unauthorized_handler.dart';
import '../../../core/storage/local_storage.dart';
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
  @override
  AuthSessionState build() {
    return const AuthSessionState(status: AuthStatus.unknown);
  }

  Future<void> restoreSession() async {
    try {
      final preferences = getIt<PreferencesService>();
      final secureStorage = getIt<SecureStorageService>();

      final token = await secureStorage.getAccessToken();
      final isLoggedIn = preferences.isLoggedIn;
      final role = UserRole.fromString(preferences.userRole);

      if (!isLoggedIn || token == null || token.isEmpty || role == null) {
        state = const AuthSessionState(status: AuthStatus.unauthenticated);
        return;
      }

      state = AuthSessionState(
        status: AuthStatus.authenticated,
        user: AuthUser(
          id: preferences.userId ?? '',
          email: preferences.userEmail ?? '',
          name: preferences.userName ?? '',
          role: role,
        ),
      );
    } catch (_) {
      state = const AuthSessionState(status: AuthStatus.unauthenticated);
    }
  }

  void markUnauthenticated() {
    UnauthorizedHandler.reset();
    state = const AuthSessionState(status: AuthStatus.unauthenticated);
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
  AuthSessionNotifier.new,
);
