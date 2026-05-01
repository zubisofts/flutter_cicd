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

  // ── Slack Notifications ───────────────────────────────────────────────────

  static const _slackPrefix = 'cicd.slack';

  Future<void> saveSlackConfig(SlackConfig config) async {
    await Future.wait([
      _storage.write(
          key: '$_slackPrefix.enabled', value: config.enabled.toString()),
      _storage.write(key: '$_slackPrefix.webhook_url', value: config.webhookUrl),
    ]);
  }

  Future<SlackConfig> loadSlackConfig() async {
    final values = await Future.wait([
      _storage.read(key: '$_slackPrefix.enabled'),
      _storage.read(key: '$_slackPrefix.webhook_url'),
    ]);
    return SlackConfig(
      enabled: values[0] == 'true',
      webhookUrl: values[1] ?? '',
    );
  }

  // ── SMTP / Email Notifications ────────────────────────────────────────────

  static const _smtpPrefix = 'cicd.smtp';

  Future<void> saveSmtpConfig(SmtpConfig config) async {
    await Future.wait([
      _storage.write(
          key: '$_smtpPrefix.enabled', value: config.enabled.toString()),
      _storage.write(key: '$_smtpPrefix.host', value: config.host),
      _storage.write(
          key: '$_smtpPrefix.port', value: config.port.toString()),
      _storage.write(key: '$_smtpPrefix.username', value: config.username),
      _storage.write(key: '$_smtpPrefix.password', value: config.password),
      _storage.write(key: '$_smtpPrefix.recipient', value: config.recipient),
      _storage.write(
          key: '$_smtpPrefix.use_ssl', value: config.useSsl.toString()),
    ]);
  }

  Future<SmtpConfig> loadSmtpConfig() async {
    final values = await Future.wait([
      _storage.read(key: '$_smtpPrefix.enabled'),
      _storage.read(key: '$_smtpPrefix.host'),
      _storage.read(key: '$_smtpPrefix.port'),
      _storage.read(key: '$_smtpPrefix.username'),
      _storage.read(key: '$_smtpPrefix.password'),
      _storage.read(key: '$_smtpPrefix.recipient'),
      _storage.read(key: '$_smtpPrefix.use_ssl'),
    ]);
    return SmtpConfig(
      enabled: values[0] == 'true',
      host: values[1] ?? '',
      port: int.tryParse(values[2] ?? '') ?? 587,
      username: values[3] ?? '',
      password: values[4] ?? '',
      recipient: values[5] ?? '',
      useSsl: values[6] == 'true',
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

class SlackConfig {
  final bool enabled;
  final String webhookUrl;

  const SlackConfig({this.enabled = false, this.webhookUrl = ''});

  bool get isConfigured => webhookUrl.isNotEmpty;
}

class SmtpConfig {
  final bool enabled;
  final String host;
  final int port;
  final String username;
  final String password;
  final String recipient;
  final bool useSsl;

  const SmtpConfig({
    this.enabled = false,
    this.host = '',
    this.port = 587,
    this.username = '',
    this.password = '',
    this.recipient = '',
    this.useSsl = false,
  });

  bool get isConfigured => host.isNotEmpty && recipient.isNotEmpty;
}
