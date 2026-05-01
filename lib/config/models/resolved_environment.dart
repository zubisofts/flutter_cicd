import 'env_config.dart';

class ResolvedEnvironment {
  final String name;
  final String displayName;
  final int colorValue;
  final String androidPackageName;
  final String iosBundleId;
  final String androidFirebaseAppId;
  final String iosFirebaseAppId;
  final String androidFlavor;
  final String iosFlavor;
  final String dartDefineFromFile;
  final DistributionRules distributionRules;
  final SigningConfig androidSigning;
  final IosEnvConfig iosConfig;
  final String resolvedVersion;
  final int buildNumber;
  final bool requiresConfirmation;
  final String? confirmationPhrase;
  final Map<String, String> shellEnv;

  const ResolvedEnvironment({
    required this.name,
    required this.displayName,
    required this.colorValue,
    required this.androidPackageName,
    required this.iosBundleId,
    required this.androidFirebaseAppId,
    required this.iosFirebaseAppId,
    this.androidFlavor = '',
    this.iosFlavor = '',
    this.dartDefineFromFile = '',
    required this.distributionRules,
    required this.androidSigning,
    required this.iosConfig,
    required this.resolvedVersion,
    required this.buildNumber,
    required this.requiresConfirmation,
    this.confirmationPhrase,
    required this.shellEnv,
  });

  bool get isProduction => name == 'prod';
}

class BuildOptions {
  final String projectId;
  final String branch;
  final String versionName;
  final int buildNumber;
  final List<String> platforms;
  final List<String> targets;

  const BuildOptions({
    required this.projectId,
    required this.branch,
    required this.versionName,
    required this.buildNumber,
    required this.platforms,
    required this.targets,
  });
}
