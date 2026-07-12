import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/di_callbacks.dart';
import '../di/service_locator.dart';
import '../network/api_client.dart';
import '../network/api_error_notifier.dart';
import '../network/dio_client.dart';
import '../network/failure.dart';
import '../network/unauthorized_handler.dart';

final apiErrorStateProvider =
    StateProvider<ApiErrorState?>((ref) => null);

final sessionExpiredProvider = StateProvider<bool>((ref) => false);

/// Wires GetIt callback holders to Riverpod UI state. Must be watched at app root.
final diBridgeProvider = Provider<bool>((ref) {
  getIt<ApiErrorCallbackHolder>().callback = (error) {
    ref.read(apiErrorStateProvider.notifier).state = error;
  };

  getIt<SessionExpiredBroadcaster>().onSessionExpired = () {
    ref.read(sessionExpiredProvider.notifier).state = true;
  };

  ref.onDispose(() {
    getIt<ApiErrorCallbackHolder>().callback = null;
    getIt<SessionExpiredBroadcaster>().onSessionExpired = null;
  });

  return true;
});

final apiErrorNotifierProvider = Provider<ApiErrorNotifier>(
  (ref) => getIt<ApiErrorNotifier>(),
);

final unauthorizedHandlerProvider = Provider<UnauthorizedHandler>(
  (ref) => getIt<UnauthorizedHandler>(),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => getIt<DioClient>(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => getIt<ApiClient>(),
);

void showApiError(WidgetRef ref, Failure failure) {
  ref.read(apiErrorNotifierProvider).show(failure);
}
