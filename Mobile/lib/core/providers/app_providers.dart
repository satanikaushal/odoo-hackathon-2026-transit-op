import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/service_locator.dart';
import '../storage/local_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return getIt<PreferencesService>().themeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await getIt<PreferencesService>().saveThemeMode(mode);
    state = mode;
  }
}
