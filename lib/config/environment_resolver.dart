import 'dart:io';
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
    final appleCreds = await _credentials.loadAppleCredentials(
      projectId: projectId,
      envName: envName,
    );
    final firebaseToken = await _credentials.loadFirebaseToken();

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
      appleCreds: appleCreds,
      firebaseToken: firebaseToken,
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

  Map<String, String> _buildShellEnv({
    required EnvConfig envConfig,
    required AndroidSigningCredentials androidCreds,
    required AppleCredentials appleCreds,
    required String firebaseToken,
  }) {
    final sysEnv = Platform.environment;
    return {
      // Android signing — Keychain values take priority
      'KEYSTORE_PASSWORD': androidCreds.keystorePassword.isNotEmpty
          ? androidCreds.keystorePassword
          : sysEnv[envConfig.android.signing.keystorePasswordEnv] ?? '',
      'KEY_PASSWORD': androidCreds.keyPassword.isNotEmpty
          ? androidCreds.keyPassword
          : sysEnv[envConfig.android.signing.keyPasswordEnv] ?? '',

      // Firebase — Keychain first, then env var
      'FIREBASE_TOKEN': firebaseToken.isNotEmpty
          ? firebaseToken
          : sysEnv['FIREBASE_TOKEN'] ?? '',

      // Apple / TestFlight
      'FASTLANE_USER': appleCreds.appleId.isNotEmpty
          ? appleCreds.appleId
          : sysEnv['FASTLANE_USER'] ?? '',
      'FASTLANE_PASSWORD': appleCreds.appSpecificPassword.isNotEmpty
          ? appleCreds.appSpecificPassword
          : sysEnv['FASTLANE_PASSWORD'] ?? '',

      // Play Store JSON key path (still env-var only — path, not secret)
      'PLAY_STORE_JSON_KEY': sysEnv['PLAY_STORE_JSON_KEY'] ?? '',
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
