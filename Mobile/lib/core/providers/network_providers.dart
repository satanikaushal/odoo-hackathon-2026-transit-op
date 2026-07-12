import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_error_notifier.dart';
import '../network/dio_client.dart';
import '../network/failure.dart';
import '../network/unauthorized_handler.dart';
import 'core_providers.dart';

final apiErrorStateProvider =
    StateProvider<ApiErrorState?>((ref) => null);

final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final apiErrorNotifierProvider = Provider<ApiErrorNotifier>((ref) {
  return ApiErrorNotifier((error) {
    ref.read(apiErrorStateProvider.notifier).state = error;
  });
});

final unauthorizedHandlerProvider = Provider<UnauthorizedHandler>((ref) {
  return UnauthorizedHandler(
    secureStorage: ref.watch(secureStorageProvider),
    preferences: ref.watch(preferencesServiceProvider),
    apiErrorNotifier: ref.watch(apiErrorNotifierProvider),
    onSessionExpired: () {
      ref.read(sessionExpiredProvider.notifier).state = true;
    },
  );
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    secureStorage: ref.watch(secureStorageProvider),
    unauthorizedHandler: ref.watch(unauthorizedHandlerProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioClientProvider).dio);
});

/// Shows a global API error once. Repositories can call this for fail-fast flows.
void showApiError(WidgetRef ref, Failure failure) {
  ref.read(apiErrorNotifierProvider).show(failure);
}
