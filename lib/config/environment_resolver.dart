import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'models/env_config.dart';
import 'models/resolved_environment.dart';
import 'config_repository.dart';
import '../services/credential_store.dart';

class EnvironmentResolver {
  final ConfigRepository _repo;
  final CredentialStore _credentials;

  EnvironmentResolver(this._repo, this._credentials);

  Future<ResolvedEnvironment> resolve({
    required String projectId,
    required String envName,
    required BuildOptions options,
    required String runId,
  }) async {
    final project = await _repo.loadProject(projectId);
    final envConfig = await _repo.loadEnv(projectId, envName);

    _validateBranchAllowed(envConfig, options.branch);

    final versionSuffix = project.versioning.suffixPerEnv[envName] ?? '';
    final fullVersion = '${options.versionName}$versionSuffix';

    final colorRaw = envConfig.color.replaceFirst('0x', '');
    final colorValue = int.tryParse(colorRaw, radix: 16) ?? 0xFF607D8B;

    // Load credentials: Keychain first, fall back to env vars
    final androidCreds = await _credentials.loadAndroidSigning(
      projectId: projectId,
      envName: envName,
    );
    final appleApiKey = await _credentials.loadAppleApiKey(
      projectId: projectId,
      envName: envName,
    );

    // Service account JSON content is stored in Keychain.
    // Write to a per-run temp file so the process can reference a file path.
    // The pipeline runner deletes the temp dir when the run finishes.
    final firebaseContent = await _credentials.loadFirebaseServiceAccount();
    final playStoreContent = await _credentials.loadPlayStoreKey();
    final matchConfig = await _credentials.loadMatchConfig(projectId);
    final gitHubToken = await _credentials.loadGitHubToken(projectId);

    final firebaseCredPath = await _writeTempCredential(
      runId: runId,
      filename: 'firebase_sa.json',
      content: firebaseContent,
    );
    final playStoreCredPath = await _writeTempCredential(
      runId: runId,
      filename: 'play_store_sa.json',
      content: playStoreContent,
    );

    // Merge signing config: Keychain values override YAML placeholders
    final resolvedSigning = androidCreds.isConfigured
        ? SigningConfig(
            keystore: androidCreds.keystorePath,
            keyAlias: androidCreds.keyAlias,
            keystorePasswordEnv: '',
            keyPasswordEnv: '',
          )
        : envConfig.android.signing;

    final shellEnv = _buildShellEnv(
      envConfig: envConfig,
      androidCreds: androidCreds,
      appleApiKey: appleApiKey,
      firebaseCredPath: firebaseCredPath,
      playStoreCredPath: playStoreCredPath,
      matchConfig: matchConfig,
      gitHubToken: gitHubToken,
    );

    return ResolvedEnvironment(
      name: envName,
      displayName: envConfig.displayName,
      colorValue: colorValue,
      androidPackageName: envConfig.android.packageName,
      iosBundleId: envConfig.ios.bundleId,
      androidFirebaseAppId: envConfig.android.firebaseAppId,
      iosFirebaseAppId: envConfig.ios.firebaseAppId,
      androidFlavor: envConfig.android.flavor,
      iosFlavor: envConfig.ios.flavor,
      dartDefineFromFile: envConfig.dartDefineFromFile,
      distributionRules: envConfig.distribution,
      androidSigning: resolvedSigning,
      iosConfig: envConfig.ios,
      resolvedVersion: fullVersion,
      buildNumber: options.buildNumber,
      requiresConfirmation: envConfig.safety.requireConfirmation,
      confirmationPhrase: envConfig.safety.confirmationPhrase,
      shellEnv: shellEnv,
    );
  }

  // Writes credential JSON content to ~/.cicd/.credentials/<runId>/<filename>.
  // Returns the path, or '' if content is empty.
  // The directory is scoped to the run ID so parallel future runs won't clash,
  // and the pipeline runner deletes the whole dir when the run finishes.
  static Future<String> _writeTempCredential({
    required String runId,
    required String filename,
    required String content,
  }) async {
    if (content.isEmpty) return '';
    final home = Platform.environment['HOME'] ?? '/tmp';
    final dir = Directory(p.join(home, '.cicd', '.credentials', runId));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content, flush: true);
    return file.path;
  }

  // Called by PipelineRunner after a run finishes.
  static Future<void> cleanTempCredentials(String runId) async {
    final home = Platform.environment['HOME'];
    if (home == null) return;
    final dir =
        Directory(p.join(home, '.cicd', '.credentials', runId));
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Map<String, String> _buildShellEnv({
    required EnvConfig envConfig,
    required AndroidSigningCredentials androidCreds,
    required AppleApiKey appleApiKey,
    required String firebaseCredPath,
    required String playStoreCredPath,
    required MatchConfig matchConfig,
    required String gitHubToken,
  }) {
    final sysEnv = Platform.environment;
    // Derive Match type from the iOS export method (e.g. "app-store" → "appstore")
    final matchType = switch (envConfig.ios.exportMethod) {
      'ad-hoc' => 'adhoc',
      'enterprise' => 'enterprise',
      'development' => 'development',
      _ => 'appstore',
    };
    return {
      // Android signing — Keychain values take priority
      'KEYSTORE_PASSWORD': androidCreds.keystorePassword.isNotEmpty
          ? androidCreds.keystorePassword
          : sysEnv[envConfig.android.signing.keystorePasswordEnv] ?? '',
      'KEY_PASSWORD': androidCreds.keyPassword.isNotEmpty
          ? androidCreds.keyPassword
          : sysEnv[envConfig.android.signing.keyPasswordEnv] ?? '',

      // Firebase App Distribution — service account written to a temp file
      'GOOGLE_APPLICATION_CREDENTIALS': firebaseCredPath.isNotEmpty
          ? firebaseCredPath
          : sysEnv['GOOGLE_APPLICATION_CREDENTIALS'] ?? '',

      // App Store Connect API Key
      'ASC_KEY_ID': appleApiKey.keyId.isNotEmpty
          ? appleApiKey.keyId
          : sysEnv['ASC_KEY_ID'] ?? '',
      'ASC_ISSUER_ID': appleApiKey.issuerId.isNotEmpty
          ? appleApiKey.issuerId
          : sysEnv['ASC_ISSUER_ID'] ?? '',
      'ASC_KEY_CONTENT': appleApiKey.privateKeyContent.isNotEmpty
          ? base64Encode(utf8.encode(appleApiKey.privateKeyContent))
          : sysEnv['ASC_KEY_CONTENT'] ?? '',

      // Play Store — service account written to a temp file
      'PLAY_STORE_JSON_KEY': playStoreCredPath.isNotEmpty
          ? playStoreCredPath
          : sysEnv['PLAY_STORE_JSON_KEY'] ?? '',

      // Fastlane Match — certificate & profile sync
      'MATCH_GIT_URL': matchConfig.gitUrl.isNotEmpty
          ? matchConfig.gitUrl
          : sysEnv['MATCH_GIT_URL'] ?? '',
      'MATCH_GIT_BRANCH': matchConfig.branch.isNotEmpty
          ? matchConfig.branch
          : sysEnv['MATCH_GIT_BRANCH'] ?? 'main',
      'MATCH_PASSWORD': matchConfig.password.isNotEmpty
          ? matchConfig.password
          : sysEnv['MATCH_PASSWORD'] ?? '',
      'MATCH_TYPE': matchType,
      'MATCH_READONLY': matchConfig.readonly ? 'true' : 'false',

      // GitHub PAT — consumed by git_checkout_step to rewrite the clone URL
      // to HTTPS. Not passed directly to git; the step injects it into the URL.
      if (gitHubToken.isNotEmpty) 'GITHUB_TOKEN': gitHubToken,
    };
  }

  void _validateBranchAllowed(EnvConfig config, String branch) {
    if (!config.safety.requireCleanBranch) return;
    final allowed = config.safety.allowedBranches ?? [];
    if (allowed.isEmpty) return;
    final match = allowed.any((pattern) => _matchGlob(pattern, branch));
    if (!match) throw BranchNotAllowedException(branch, allowed);
  }

  bool _matchGlob(String pattern, String value) {
    if (!pattern.contains('*')) return pattern == value;
    final prefix = pattern.substring(0, pattern.indexOf('*'));
    return value.startsWith(prefix);
  }
}

class BranchNotAllowedException implements Exception {
  final String branch;
  final List<String> allowed;
  BranchNotAllowedException(this.branch, this.allowed);
  @override
  String toString() =>
      'Branch "$branch" is not allowed for this environment. '
      'Allowed: ${allowed.join(', ')}';
}
