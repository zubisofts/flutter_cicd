class EnvConfig {
  final String name;
  final String displayName;
  final String color;
  final AndroidEnvConfig android;
  final IosEnvConfig ios;
  final DistributionRules distribution;
  final SafetyConfig safety;
  /// Path to a JSON file passed via --dart-define-from-file (optional).
  final String dartDefineFromFile;

  const EnvConfig({
    required this.name,
    required this.displayName,
    required this.color,
    required this.android,
    required this.ios,
    required this.distribution,
    required this.safety,
    this.dartDefineFromFile = '',
  });

  factory EnvConfig.fromMap(Map map) {
    return EnvConfig(
      name: map['name'] as String,
      displayName: map['display_name'] as String? ?? map['name'] as String,
      color: map['color'] as String? ?? '0xFF607D8B',
      android: AndroidEnvConfig.fromMap(map['android'] as Map? ?? {}),
      ios: IosEnvConfig.fromMap(map['ios'] as Map? ?? {}),
      distribution:
          DistributionRules.fromMap(map['distribution'] as Map? ?? {}),
      safety: SafetyConfig.fromMap(map['safety'] as Map? ?? {}),
      dartDefineFromFile: map['dart_define_from_file'] as String? ?? '',
    );
  }
}

class AndroidEnvConfig {
  final String packageName;
  final String firebaseAppId;
  final String flavor;
  final SigningConfig signing;

  const AndroidEnvConfig({
    required this.packageName,
    required this.firebaseAppId,
    required this.flavor,
    required this.signing,
  });

  factory AndroidEnvConfig.fromMap(Map map) => AndroidEnvConfig(
        packageName: map['package_name'] as String? ?? '',
        firebaseAppId: map['firebase_app_id'] as String? ?? '',
        flavor: map['flavor'] as String? ?? '',
        signing: SigningConfig.fromMap(map['signing'] as Map? ?? {}),
      );
}

class SigningConfig {
  final String keystore;
  final String keyAlias;
  final String keystorePasswordEnv;
  final String keyPasswordEnv;

  const SigningConfig({
    required this.keystore,
    required this.keyAlias,
    required this.keystorePasswordEnv,
    required this.keyPasswordEnv,
  });

  factory SigningConfig.fromMap(Map map) => SigningConfig(
        keystore: map['keystore'] as String? ?? '',
        keyAlias: map['key_alias'] as String? ?? '',
        keystorePasswordEnv:
            map['keystore_password_env'] as String? ?? '',
        keyPasswordEnv: map['key_password_env'] as String? ?? '',
      );
}

class IosEnvConfig {
  final String bundleId;
  final String firebaseAppId;
  final String provisioningProfile;
  final String teamId;
  final String flavor;
  /// app-store | ad-hoc | development | enterprise
  final String exportMethod;

  const IosEnvConfig({
    required this.bundleId,
    required this.firebaseAppId,
    required this.provisioningProfile,
    required this.teamId,
    required this.flavor,
    this.exportMethod = 'app-store',
  });

  factory IosEnvConfig.fromMap(Map map) => IosEnvConfig(
        bundleId: map['bundle_id'] as String? ?? '',
        firebaseAppId: map['firebase_app_id'] as String? ?? '',
        provisioningProfile: map['provisioning_profile'] as String? ?? '',
        teamId: map['team_id'] as String? ?? '',
        flavor: map['flavor'] as String? ?? '',
        exportMethod: map['export_method'] as String? ?? 'app-store',
      );
}

class DistributionRules {
  final FirebaseDistConfig? firebase;
  final bool testflight;
  final PlayStoreConfig? playStore;

  const DistributionRules({
    this.firebase,
    required this.testflight,
    this.playStore,
  });

  factory DistributionRules.fromMap(Map map) {
    final fb = map['firebase'];
    final ps = map['play_store'];
    return DistributionRules(
      firebase: fb != null && fb is Map
          ? FirebaseDistConfig.fromMap(fb)
          : null,
      testflight: map['testflight'] == true,
      playStore:
          ps != null && ps is Map ? PlayStoreConfig.fromMap(ps) : null,
    );
  }
}

class FirebaseDistConfig {
  final bool enabled;
  final List<String> testerGroups;

  const FirebaseDistConfig({
    required this.enabled,
    required this.testerGroups,
  });

  factory FirebaseDistConfig.fromMap(Map map) => FirebaseDistConfig(
        enabled: map['enabled'] == true,
        testerGroups: (map['tester_groups'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class PlayStoreConfig {
  final bool enabled;
  final String track;
  final int rolloutPercentage;

  const PlayStoreConfig({
    required this.enabled,
    required this.track,
    required this.rolloutPercentage,
  });

  factory PlayStoreConfig.fromMap(Map map) => PlayStoreConfig(
        enabled: map['enabled'] == true,
        track: map['track'] as String? ?? 'internal',
        rolloutPercentage: map['rollout_percentage'] as int? ?? 100,
      );
}

class SafetyConfig {
  final bool requireConfirmation;
  final String? confirmationPhrase;
  final bool requireCleanBranch;
  final List<String>? allowedBranches;
  final bool disallowSnapshotVersions;

  const SafetyConfig({
    required this.requireConfirmation,
    this.confirmationPhrase,
    required this.requireCleanBranch,
    this.allowedBranches,
    required this.disallowSnapshotVersions,
  });

  factory SafetyConfig.fromMap(Map map) => SafetyConfig(
        requireConfirmation: map['require_confirmation'] == true,
        confirmationPhrase: map['confirmation_phrase'] as String?,
        requireCleanBranch: map['require_clean_branch'] == true,
        allowedBranches: (map['allowed_branches'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        disallowSnapshotVersions:
            map['disallow_snapshot_versions'] == true,
      );
}
