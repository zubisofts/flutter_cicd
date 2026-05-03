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
  // Stores the full service account JSON content in Keychain.
  // At build time the content is written to a temp file for the duration of
  // the run, then deleted. This means the user's source file can be moved or
  // deleted without breaking builds.

  Future<void> saveFirebaseServiceAccount(String jsonContent) async {
    await _storage.write(
        key: 'cicd.firebase.service_account', value: jsonContent);
  }

  Future<String> loadFirebaseServiceAccount() async {
    return await _storage.read(key: 'cicd.firebase.service_account') ?? '';
  }

  // ── Play Store ────────────────────────────────────────────────────────────
  // Same approach: stores JSON content, not path.

  Future<void> savePlayStoreKey(String jsonContent) async {
    await _storage.write(key: 'cicd.playstore.json_key', value: jsonContent);
  }

  Future<String> loadPlayStoreKey() async {
    return await _storage.read(key: 'cicd.playstore.json_key') ?? '';
  }

  // ── App Store Connect API Key (replaces username/password for TestFlight) ──
  // API keys are account-scoped in App Store Connect (Users & Access → Keys).
  // They work without 2FA prompts and don't expire like session tokens.

  Future<void> saveAppleApiKey({
    required String projectId,
    required String envName,
    required String keyId,
    required String issuerId,
    required String privateKeyContent,
  }) async {
    await Future.wait([
      _storage.write(
          key: _k(projectId, envName, 'apple.asc_key_id'), value: keyId),
      _storage.write(
          key: _k(projectId, envName, 'apple.asc_issuer_id'), value: issuerId),
      _storage.write(
          key: _k(projectId, envName, 'apple.asc_private_key'),
          value: privateKeyContent),
    ]);
  }

  Future<AppleApiKey> loadAppleApiKey({
    required String projectId,
    required String envName,
  }) async {
    final values = await Future.wait([
      _storage.read(key: _k(projectId, envName, 'apple.asc_key_id')),
      _storage.read(key: _k(projectId, envName, 'apple.asc_issuer_id')),
      _storage.read(key: _k(projectId, envName, 'apple.asc_private_key')),
    ]);
    return AppleApiKey(
      keyId: values[0] ?? '',
      issuerId: values[1] ?? '',
      privateKeyContent: values[2] ?? '',
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

  // ── Teams Notifications ───────────────────────────────────────────────────

  static const _teamsPrefix = 'cicd.teams';

  Future<void> saveTeamsConfig(TeamsConfig config) async {
    await Future.wait([
      _storage.write(
          key: '$_teamsPrefix.enabled', value: config.enabled.toString()),
      _storage.write(key: '$_teamsPrefix.webhook_url', value: config.webhookUrl),
    ]);
  }

  Future<TeamsConfig> loadTeamsConfig() async {
    final values = await Future.wait([
      _storage.read(key: '$_teamsPrefix.enabled'),
      _storage.read(key: '$_teamsPrefix.webhook_url'),
    ]);
    return TeamsConfig(
      enabled: values[0] == 'true',
      webhookUrl: values[1] ?? '',
    );
  }

  // ── Google Chat Notifications ─────────────────────────────────────────────

  static const _googleChatPrefix = 'cicd.google_chat';

  Future<void> saveGoogleChatConfig(GoogleChatConfig config) async {
    await Future.wait([
      _storage.write(
          key: '$_googleChatPrefix.enabled',
          value: config.enabled.toString()),
      _storage.write(
          key: '$_googleChatPrefix.webhook_url', value: config.webhookUrl),
    ]);
  }

  Future<GoogleChatConfig> loadGoogleChatConfig() async {
    final values = await Future.wait([
      _storage.read(key: '$_googleChatPrefix.enabled'),
      _storage.read(key: '$_googleChatPrefix.webhook_url'),
    ]);
    return GoogleChatConfig(
      enabled: values[0] == 'true',
      webhookUrl: values[1] ?? '',
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

class AppleApiKey {
  final String keyId;
  final String issuerId;
  final String privateKeyContent;

  const AppleApiKey({
    this.keyId = '',
    this.issuerId = '',
    this.privateKeyContent = '',
  });

  bool get isConfigured =>
      keyId.isNotEmpty && issuerId.isNotEmpty && privateKeyContent.isNotEmpty;
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

class TeamsConfig {
  final bool enabled;
  final String webhookUrl;

  const TeamsConfig({this.enabled = false, this.webhookUrl = ''});

  bool get isConfigured => webhookUrl.isNotEmpty;
}

class GoogleChatConfig {
  final bool enabled;
  final String webhookUrl;

  const GoogleChatConfig({this.enabled = false, this.webhookUrl = ''});

  bool get isConfigured => webhookUrl.isNotEmpty;
}
