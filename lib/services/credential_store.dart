import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive signing credentials in the macOS Keychain.
/// Keys are namespaced by project + environment to avoid collisions.
class CredentialStore {
  // No groupId — groupId requires a keychain-access-groups entitlement
  // which is unavailable in a non-sandboxed debug build.
  // useDataProtectionKeychain: false uses the traditional login keychain,
  // which works without any entitlement.
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(
      useDataProtectionKeyChain: false,
      synchronizable: false,
    ),
  );

  // ── Key builders ─────────────────────────────────────────────────────────

  static String _k(String project, String env, String field) =>
      'cicd.$project.$env.$field';

  // ── Android signing ───────────────────────────────────────────────────────

  Future<void> saveAndroidSigning({
    required String projectId,
    required String envName,
    required String keystorePath,
    required String keyAlias,
    required String keystorePassword,
    required String keyPassword,
  }) async {
    await Future.wait([
      _storage.write(
          key: _k(projectId, envName, 'android.keystore_path'),
          value: keystorePath),
      _storage.write(
          key: _k(projectId, envName, 'android.key_alias'),
          value: keyAlias),
      _storage.write(
          key: _k(projectId, envName, 'android.keystore_password'),
          value: keystorePassword),
      _storage.write(
          key: _k(projectId, envName, 'android.key_password'),
          value: keyPassword),
    ]);
  }

  Future<AndroidSigningCredentials> loadAndroidSigning({
    required String projectId,
    required String envName,
  }) async {
    final values = await Future.wait([
      _storage.read(key: _k(projectId, envName, 'android.keystore_path')),
      _storage.read(key: _k(projectId, envName, 'android.key_alias')),
      _storage.read(key: _k(projectId, envName, 'android.keystore_password')),
      _storage.read(key: _k(projectId, envName, 'android.key_password')),
    ]);
    return AndroidSigningCredentials(
      keystorePath: values[0] ?? '',
      keyAlias: values[1] ?? '',
      keystorePassword: values[2] ?? '',
      keyPassword: values[3] ?? '',
    );
  }

  // ── Firebase ──────────────────────────────────────────────────────────────

  Future<void> saveFirebaseToken(String token) async {
    await _storage.write(key: 'cicd.firebase.token', value: token);
  }

  Future<String> loadFirebaseToken() async {
    return await _storage.read(key: 'cicd.firebase.token') ?? '';
  }

  // ── App Store / TestFlight ────────────────────────────────────────────────

  Future<void> saveAppleCredentials({
    required String projectId,
    required String envName,
    required String appleId,
    required String appSpecificPassword,
  }) async {
    await Future.wait([
      _storage.write(
          key: _k(projectId, envName, 'apple.id'), value: appleId),
      _storage.write(
          key: _k(projectId, envName, 'apple.app_specific_password'),
          value: appSpecificPassword),
    ]);
  }

  Future<AppleCredentials> loadAppleCredentials({
    required String projectId,
    required String envName,
  }) async {
    final values = await Future.wait([
      _storage.read(key: _k(projectId, envName, 'apple.id')),
      _storage.read(key: _k(projectId, envName, 'apple.app_specific_password')),
    ]);
    return AppleCredentials(
      appleId: values[0] ?? '',
      appSpecificPassword: values[1] ?? '',
    );
  }

  Future<void> clearProject(String projectId) async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith('cicd.$projectId.')) {
        await _storage.delete(key: key);
      }
    }
  }
}

class AndroidSigningCredentials {
  final String keystorePath;
  final String keyAlias;
  final String keystorePassword;
  final String keyPassword;

  const AndroidSigningCredentials({
    required this.keystorePath,
    required this.keyAlias,
    required this.keystorePassword,
    required this.keyPassword,
  });

  bool get isConfigured =>
      keystorePath.isNotEmpty && keyAlias.isNotEmpty;
}

class AppleCredentials {
  final String appleId;
  final String appSpecificPassword;

  const AppleCredentials({
    required this.appleId,
    required this.appSpecificPassword,
  });

  bool get isConfigured => appleId.isNotEmpty;
}
