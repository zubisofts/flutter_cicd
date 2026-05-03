import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService extends ValueNotifier<ThemeMode> {
  static const _key = 'cicd.theme.mode';
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(
      useDataProtectionKeyChain: false,
      synchronizable: false,
    ),
  );

  ThemeService._(super.mode);

  static Future<ThemeService> load() async {
    final raw = await _storage.read(key: _key);
    final mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ThemeService._(mode);
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    await _storage.write(
      key: _key,
      value: switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}
