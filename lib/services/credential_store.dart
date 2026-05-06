import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores all sensitive credentials as a single JSON blob in the macOS
/// Keychain under [_masterKey].
///
/// One blob → one keychain entry → one password prompt on reinstall instead
/// of one prompt per field. After [_ensureLoaded] returns, all reads are
/// in-memory (synchronous under the hood).
///
/// Migration: if [_masterKey] is absent but legacy `cicd.*` keys exist,
/// they are consolidated automatically on first access.
class CredentialStore {
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(
      useDataProtectionKeyChain: false,
      synchronizable: false,
    ),
  );

  static const _masterKey = 'cicd.credentials';

  Map<String, String>? _cache;
  Future<void>? _loadFuture;

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    _loadFuture ??= _load();
    await _loadFuture;
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _masterKey);
    if (raw != null) {
      try {
        _cache = Map<String, String>.from(jsonDecode(raw) as Map);
      } catch (_) {
        _cache = {};
      }
      return;
    }

    // Migration: read all legacy per-key entries and consolidate.
    // On a fresh install this is a no-op; on first run after upgrading from
    // the old format it merges all existing keys into one entry.
    try {
      final all = await _storage.readAll();
      final legacy = <String, String>{};
      for (final e in all.entries) {
        if (e.key.startsWith('cicd.')) legacy[e.key] = e.value;
      }
      _cache = legacy;
      if (legacy.isNotEmpty) {
        await _storage.write(key: _masterKey, value: jsonEncode(legacy));
        for (final key in legacy.keys) {
          await _storage.delete(key: key);
        }
      } else {
        _cache = {};
      }
    } catch (_) {
      _cache = {};
    }
  }

  Future<String?> _get(String key) async {
    await _ensureLoaded();
    return _cache![key];
  }

  Future<void> _set(String key, String value) async {
    await _ensureLoaded();
    _cache![key] = value;
    await _flush();
  }

  Future<void> _flush() async {
    await _storage.write(key: _masterKey, value: jsonEncode(_cache));
  }

  // ── Key builders ──────────────────────────────────────────────────────────

  static String _k(String project, String env, String field) =>
      'cicd.$project.$env.$field';

  static String _matchKey(String projectId, String field) =>
      'cicd.$projectId.match.$field';

  // ── Android signing ───────────────────────────────────────────────────────

  Future<void> saveAndroidSigning({
    required String projectId,
    required String envName,
    required String keystorePath,
    required String keyAlias,
    required String keystorePassword,
    required String keyPassword,
  }) async {
    await _ensureLoaded();
    _cache![_k(projectId, envName, 'android.keystore_path')] = keystorePath;
    _cache![_k(projectId, envName, 'android.key_alias')] = keyAlias;
    _cache![_k(projectId, envName, 'android.keystore_password')] =
        keystorePassword;
    _cache![_k(projectId, envName, 'android.key_password')] = keyPassword;
    await _flush();
  }

  Future<AndroidSigningCredentials> loadAndroidSigning({
    required String projectId,
    required String envName,
  }) async {
    await _ensureLoaded();
    return AndroidSigningCredentials(
      keystorePath:
          _cache![_k(projectId, envName, 'android.keystore_path')] ?? '',
      keyAlias: _cache![_k(projectId, envName, 'android.key_alias')] ?? '',
      keystorePassword:
          _cache![_k(projectId, envName, 'android.keystore_password')] ?? '',
      keyPassword:
          _cache![_k(projectId, envName, 'android.key_password')] ?? '',
    );
  }

  // ── Firebase ──────────────────────────────────────────────────────────────

  Future<void> saveFirebaseServiceAccount(String jsonContent) async {
    await _set('cicd.firebase.service_account', jsonContent);
  }

  Future<String> loadFirebaseServiceAccount() async {
    return await _get('cicd.firebase.service_account') ?? '';
  }

  // ── GitHub token ─────────────────────────────────────────────────────────

  Future<void> saveGitHubToken(String projectId, String token) async {
    await _set('cicd.$projectId.git.github_token', token);
  }

  Future<String> loadGitHubToken(String projectId) async {
    return await _get('cicd.$projectId.git.github_token') ?? '';
  }

  // ── Play Store ────────────────────────────────────────────────────────────

  Future<void> savePlayStoreKey(String jsonContent) async {
    await _set('cicd.playstore.json_key', jsonContent);
  }

  Future<String> loadPlayStoreKey() async {
    return await _get('cicd.playstore.json_key') ?? '';
  }

  // ── App Store Connect API Key ─────────────────────────────────────────────

  Future<void> saveAppleApiKey({
    required String projectId,
    required String envName,
    required String keyId,
    required String issuerId,
    required String privateKeyContent,
  }) async {
    await _ensureLoaded();
    _cache![_k(projectId, envName, 'apple.asc_key_id')] = keyId;
    _cache![_k(projectId, envName, 'apple.asc_issuer_id')] = issuerId;
    _cache![_k(projectId, envName, 'apple.asc_private_key')] =
        privateKeyContent;
    await _flush();
  }

  Future<AppleApiKey> loadAppleApiKey({
    required String projectId,
    required String envName,
  }) async {
    await _ensureLoaded();
    return AppleApiKey(
      keyId: _cache![_k(projectId, envName, 'apple.asc_key_id')] ?? '',
      issuerId:
          _cache![_k(projectId, envName, 'apple.asc_issuer_id')] ?? '',
      privateKeyContent:
          _cache![_k(projectId, envName, 'apple.asc_private_key')] ?? '',
    );
  }

  // ── Slack ─────────────────────────────────────────────────────────────────

  Future<void> saveSlackConfig(SlackConfig config) async {
    await _ensureLoaded();
    _cache!['cicd.slack.enabled'] = config.enabled.toString();
    _cache!['cicd.slack.webhook_url'] = config.webhookUrl;
    await _flush();
  }

  Future<SlackConfig> loadSlackConfig() async {
    await _ensureLoaded();
    return SlackConfig(
      enabled: _cache!['cicd.slack.enabled'] == 'true',
      webhookUrl: _cache!['cicd.slack.webhook_url'] ?? '',
    );
  }

  // ── SMTP ──────────────────────────────────────────────────────────────────

  Future<void> saveSmtpConfig(SmtpConfig config) async {
    await _ensureLoaded();
    _cache!['cicd.smtp.enabled'] = config.enabled.toString();
    _cache!['cicd.smtp.host'] = config.host;
    _cache!['cicd.smtp.port'] = config.port.toString();
    _cache!['cicd.smtp.username'] = config.username;
    _cache!['cicd.smtp.password'] = config.password;
    _cache!['cicd.smtp.recipient'] = config.recipient;
    _cache!['cicd.smtp.use_ssl'] = config.useSsl.toString();
    await _flush();
  }

  Future<SmtpConfig> loadSmtpConfig() async {
    await _ensureLoaded();
    return SmtpConfig(
      enabled: _cache!['cicd.smtp.enabled'] == 'true',
      host: _cache!['cicd.smtp.host'] ?? '',
      port: int.tryParse(_cache!['cicd.smtp.port'] ?? '') ?? 587,
      username: _cache!['cicd.smtp.username'] ?? '',
      password: _cache!['cicd.smtp.password'] ?? '',
      recipient: _cache!['cicd.smtp.recipient'] ?? '',
      useSsl: _cache!['cicd.smtp.use_ssl'] == 'true',
    );
  }

  // ── Teams ─────────────────────────────────────────────────────────────────

  Future<void> saveTeamsConfig(TeamsConfig config) async {
    await _ensureLoaded();
    _cache!['cicd.teams.enabled'] = config.enabled.toString();
    _cache!['cicd.teams.webhook_url'] = config.webhookUrl;
    await _flush();
  }

  Future<TeamsConfig> loadTeamsConfig() async {
    await _ensureLoaded();
    return TeamsConfig(
      enabled: _cache!['cicd.teams.enabled'] == 'true',
      webhookUrl: _cache!['cicd.teams.webhook_url'] ?? '',
    );
  }

  // ── Google Chat ───────────────────────────────────────────────────────────

  Future<void> saveGoogleChatConfig(GoogleChatConfig config) async {
    await _ensureLoaded();
    _cache!['cicd.google_chat.enabled'] = config.enabled.toString();
    _cache!['cicd.google_chat.webhook_url'] = config.webhookUrl;
    await _flush();
  }

  Future<GoogleChatConfig> loadGoogleChatConfig() async {
    await _ensureLoaded();
    return GoogleChatConfig(
      enabled: _cache!['cicd.google_chat.enabled'] == 'true',
      webhookUrl: _cache!['cicd.google_chat.webhook_url'] ?? '',
    );
  }

  // ── Fastlane Match ────────────────────────────────────────────────────────

  Future<void> saveMatchConfig({
    required String projectId,
    required String gitUrl,
    required String branch,
    required String password,
    required bool readonly,
  }) async {
    await _ensureLoaded();
    _cache![_matchKey(projectId, 'git_url')] = gitUrl;
    _cache![_matchKey(projectId, 'branch')] = branch;
    _cache![_matchKey(projectId, 'password')] = password;
    _cache![_matchKey(projectId, 'readonly')] = readonly.toString();
    await _flush();
  }

  Future<MatchConfig> loadMatchConfig(String projectId) async {
    await _ensureLoaded();
    final branch = _cache![_matchKey(projectId, 'branch')];
    return MatchConfig(
      gitUrl: _cache![_matchKey(projectId, 'git_url')] ?? '',
      branch: (branch != null && branch.isNotEmpty) ? branch : 'main',
      password: _cache![_matchKey(projectId, 'password')] ?? '',
      readonly: _cache![_matchKey(projectId, 'readonly')] != 'false',
    );
  }

  // ── Project cleanup ───────────────────────────────────────────────────────

  Future<void> clearProject(String projectId) async {
    await _ensureLoaded();
    _cache!.removeWhere((key, _) => key.startsWith('cicd.$projectId.'));
    await _flush();
  }
}

// ── Value types ───────────────────────────────────────────────────────────────

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

  bool get isConfigured => keystorePath.isNotEmpty && keyAlias.isNotEmpty;
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

class MatchConfig {
  final String gitUrl;
  final String branch;
  final String password;
  final bool readonly;

  const MatchConfig({
    this.gitUrl = '',
    this.branch = 'main',
    this.password = '',
    this.readonly = true,
  });

  bool get isConfigured => gitUrl.isNotEmpty;
}

class GoogleChatConfig {
  final bool enabled;
  final String webhookUrl;

  const GoogleChatConfig({this.enabled = false, this.webhookUrl = ''});

  bool get isConfigured => webhookUrl.isNotEmpty;
}
