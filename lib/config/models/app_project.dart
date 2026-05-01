class AppProject {
  final String id;
  final String name;
  final String repository;
  final AndroidProjectConfig android;
  final IosProjectConfig ios;
  final VersioningConfig versioning;

  const AppProject({
    required this.id,
    required this.name,
    required this.repository,
    required this.android,
    required this.ios,
    required this.versioning,
  });

  factory AppProject.fromMap(Map<dynamic, dynamic> map) {
    return AppProject(
      id: map['id'] as String,
      name: map['name'] as String,
      repository: map['repository'] as String,
      android: AndroidProjectConfig.fromMap(
          map['android'] as Map? ?? {}),
      ios: IosProjectConfig.fromMap(map['ios'] as Map? ?? {}),
      versioning: VersioningConfig.fromMap(
          map['versioning'] as Map? ?? {}),
    );
  }
}

class AndroidProjectConfig {
  final String basePackage;
  const AndroidProjectConfig({required this.basePackage});
  factory AndroidProjectConfig.fromMap(Map map) =>
      AndroidProjectConfig(basePackage: map['base_package'] as String? ?? '');
}

class IosProjectConfig {
  final String baseBundleId;
  const IosProjectConfig({required this.baseBundleId});
  factory IosProjectConfig.fromMap(Map map) =>
      IosProjectConfig(baseBundleId: map['base_bundle_id'] as String? ?? '');
}

class VersioningConfig {
  final String strategy;
  final Map<String, String> suffixPerEnv;

  const VersioningConfig({
    required this.strategy,
    required this.suffixPerEnv,
  });

  factory VersioningConfig.fromMap(Map map) {
    final suffixes = <String, String>{};
    final rawSuffix = map['suffix_per_env'] as Map?;
    if (rawSuffix != null) {
      rawSuffix.forEach((k, v) => suffixes[k.toString()] = v.toString());
    }
    return VersioningConfig(
      strategy: map['strategy'] as String? ?? 'semver',
      suffixPerEnv: suffixes,
    );
  }
}
