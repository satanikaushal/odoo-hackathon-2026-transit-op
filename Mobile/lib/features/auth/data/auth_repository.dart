import '../../../core/constants/api_endpoints.dart';
import '../../../core/firebase/fcm_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/failure.dart';
import '../../../core/network/unauthorized_handler.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/models/device_type.dart';
import '../domain/models/login_request.dart';
import '../domain/models/login_response.dart';
import '../domain/models/me_response.dart';
import '../domain/models/user.dart';
import 'auth_token_storage.dart';
import 'token_refresh_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required AuthTokenStorage tokenStorage,
    required PreferencesService preferences,
    required FcmService fcmService,
    required TokenRefreshService tokenRefreshService,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _preferences = preferences,
        _fcmService = fcmService,
        _tokenRefreshService = tokenRefreshService;

  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;
  final PreferencesService _preferences;
  final FcmService _fcmService;
  final TokenRefreshService _tokenRefreshService;

  Future<ApiResult<User>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final deviceToken = await _resolveDeviceToken();
    final request = LoginRequest(
      email: email.trim(),
      password: password,
      deviceType: DeviceType.current,
      deviceToken: deviceToken,
    );

    final result = await _apiClient.post<LoginResponse>(
      ApiEndpoints.authLogin,
      data: request.toJson(),
      parser: (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
    );

    if (result.isFailure || result.data == null) {
      return ApiResult.failure(
        result.failure ??
            const Failure(message: 'Unable to sign in. Please try again.'),
      );
    }

    await _persistLogin(
      response: result.data!,
      email: email.trim(),
      rememberMe: rememberMe,
    );

    return ApiResult.success(result.data!.user);
  }

  Future<ApiResult<User>> fetchCurrentUser() async {
    final result = await _apiClient.get<MeResponse>(
      ApiEndpoints.authMe,
      parser: (data) => MeResponse.fromJson(data as Map<String, dynamic>),
    );

    if (result.isSuccess && result.data != null) {
      await _persistMeResponse(result.data!);
    }

    if (result.isFailure) {
      return ApiResult.failure(result.failure!);
    }

    return ApiResult.success(result.data!.user);
  }

  Future<ApiResult<void>> logout() async {
    final tokens = await _tokenStorage.readTokens();
    final refreshToken = tokens?.refreshToken;

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _apiClient.post<void>(
        ApiEndpoints.authLogout,
        data: {'refreshToken': refreshToken},
      );
    }

    await _clearLocalSession();
    UnauthorizedHandler.reset();
    return ApiResult.success(null);
  }

  Future<bool> hasStoredSession() {
    return _tokenStorage.hasValidRefreshToken();
  }

  Future<bool> refreshTokens() async {
    final accessToken = await _tokenRefreshService.refreshTokens();
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<String?> _resolveDeviceToken() async {
    final cached = _fcmService.cachedToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return _fcmService.refreshToken();
  }

  Future<void> _persistLogin({
    required LoginResponse response,
    required String email,
    required bool rememberMe,
  }) async {
    await _tokenStorage.saveTokens(response.tokens);
    await _persistUser(response.user);
    await _preferences.setLoggedIn(true);
    await _preferences.setRememberMe(rememberMe);

    if (rememberMe) {
      await _preferences.saveSavedEmail(email);
    } else {
      await _preferences.clearSavedEmail();
    }
  }

  Future<void> _persistUser(User user) async {
    await _preferences.saveUserId(user.id);
    await _preferences.saveUserEmail(user.email);
    await _preferences.saveUserName(user.name);
    await _preferences.saveUserRole(user.role.value);
  }

  Future<void> _persistMeResponse(MeResponse response) async {
    await _persistUser(response.user);

    if (response.accessTokenExpiresAt != null ||
        response.refreshTokenExpiresAt != null) {
      await _tokenStorage.updateTokenExpiries(
        accessTokenExpiresAt: response.accessTokenExpiresAt,
        refreshTokenExpiresAt: response.refreshTokenExpiresAt,
      );
    }
  }

  Future<void> _clearLocalSession() async {
    await _tokenStorage.clearTokens();
    await _preferences.clearSession();
  }
}
