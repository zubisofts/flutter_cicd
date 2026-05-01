import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'models/app_project.dart';
import 'models/env_config.dart';
import 'models/pipeline_definition.dart';

class ConfigRepository {
  final String baseDir;

  ConfigRepository({String? baseDir})
      : baseDir = baseDir ??
            p.join(Platform.environment['HOME'] ?? '/tmp', '.cicd');

  String _projectDir(String projectId) =>
      p.join(baseDir, 'projects', projectId);

  Future<List<AppProject>> listProjects() async {
    final dir = Directory(p.join(baseDir, 'projects'));
    if (!await dir.exists()) return [];
    final projects = <AppProject>[];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final id = p.basename(entity.path);
        try {
          projects.add(await loadProject(id));
        } catch (_) {}
      }
    }
    return projects;
  }

  Future<AppProject> loadProject(String projectId) async {
    final file = File(p.join(_projectDir(projectId), 'app.yaml'));
    if (!await file.exists()) {
      throw ConfigNotFoundException('app.yaml not found for project: $projectId');
    }
    final content = await file.readAsString();
    final map = loadYaml(content) as Map;
    return AppProject.fromMap(map);
  }

  Future<EnvConfig> loadEnv(String projectId, String envName) async {
    final file = File(
        p.join(_projectDir(projectId), 'envs', '$envName.yaml'));
    if (!await file.exists()) {
      throw ConfigNotFoundException(
          'Environment config not found: $envName for project $projectId');
    }
    final content = await file.readAsString();
    final map = loadYaml(content) as Map;
    return EnvConfig.fromMap(map);
  }

  /// Creates the env YAML file with defaults if it does not already exist.
  Future<void> ensureEnvExists(String projectId, String envName) async {
    final envsDir = Directory(p.join(_projectDir(projectId), 'envs'));
    await envsDir.create(recursive: true);
    final file = File(p.join(envsDir.path, '$envName.yaml'));
    if (!await file.exists()) {
      await file.writeAsString(_defaultEnvYaml(envName, projectId));
    }
  }

  Future<List<String>> listEnvironments(String projectId) async {
    final dir =
        Directory(p.join(_projectDir(projectId), 'envs'));
    if (!await dir.exists()) return [];
    final envs = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.yaml')) {
        envs.add(p.basenameWithoutExtension(entity.path));
      }
    }
    return envs;
  }

  Future<PipelineDefinition> loadPipeline(
      String projectId, String pipelineName) async {
    final file = File(p.join(
        _projectDir(projectId), 'pipelines', '$pipelineName.yaml'));
    if (!await file.exists()) {
      throw ConfigNotFoundException(
          'Pipeline not found: $pipelineName for project $projectId');
    }
    final content = await file.readAsString();
    final map = loadYaml(content) as Map;
    return PipelineDefinition.fromMap(map);
  }

  /// Copies [sourcePath] into `~/.cicd/projects/{projectId}/files/` and
  /// returns the new absolute path. Safe to call repeatedly with the same file.
  Future<String> bundleFile(String projectId, String sourcePath) async {
    final filesDir =
        Directory(p.join(_projectDir(projectId), 'files'));
    await filesDir.create(recursive: true);
    final filename = p.basename(sourcePath);
    final dest = File(p.join(filesDir.path, filename));
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  /// Deletes the entire project directory (config, envs, pipelines, files).
  Future<void> deleteProject(String projectId) async {
    final dir = Directory(_projectDir(projectId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> scaffold(String projectId, String projectName,
      String repository) async {
    final projectDir = Directory(_projectDir(projectId));
    await projectDir.create(recursive: true);
    await Directory(p.join(projectDir.path, 'envs')).create();
    await Directory(p.join(projectDir.path, 'pipelines')).create();

    await File(p.join(projectDir.path, 'app.yaml'))
        .writeAsString(_defaultAppYaml(projectId, projectName, repository));

    for (final env in ['dev', 'staging', 'prod']) {
      await File(p.join(projectDir.path, 'envs', '$env.yaml'))
          .writeAsString(_defaultEnvYaml(env, projectId));
    }

    await File(p.join(projectDir.path, 'pipelines', 'mobile.yaml'))
        .writeAsString(_defaultPipelineYaml());
  }

  String _defaultAppYaml(String id, String name, String repo) => '''
id: $id
name: "$name"
repository: $repo

android:
  base_package: com.example.$id

ios:
  base_bundle_id: com.example.$id

versioning:
  strategy: semver
  suffix_per_env:
    dev: "-dev"
    staging: ""
    prod: ""
''';

  String _defaultEnvYaml(String env, String projectId) {
    final colors = {
      'dev': '0xFF4CAF50',
      'staging': '0xFFFFC107',
      'prod': '0xFFF44336',
    };
    final suffixes = {'dev': '.dev', 'staging': '.staging', 'prod': ''};
    final suffix = suffixes[env] ?? '';
    return '''
name: $env
display_name: "${env[0].toUpperCase()}${env.substring(1)}"
color: "${colors[env]}"

# Optional: path to a JSON file for --dart-define-from-file
dart_define_from_file: ""

android:
  package_name: com.example.$projectId$suffix
  firebase_app_id: ""
  flavor: ""
  signing:
    keystore: ~/.cicd/keys/$env.keystore
    key_alias: $env
    keystore_password_env: ${env.toUpperCase()}_KEYSTORE_PASS
    key_password_env: ${env.toUpperCase()}_KEY_PASS

ios:
  bundle_id: com.example.$projectId$suffix
  firebase_app_id: ""
  flavor: ""
  provisioning_profile: ""
  team_id: ""
  export_method: ${env == 'prod' ? 'app-store' : 'ad-hoc'}

distribution:
  firebase:
    enabled: ${env != 'prod'}
    tester_groups: [internal-qa]
  testflight: ${env == 'prod' || env == 'staging'}
  play_store:
    enabled: ${env == 'prod'}
    track: ${env == 'prod' ? 'production' : 'internal'}
    rollout_percentage: ${env == 'prod' ? 10 : 100}

safety:
  require_confirmation: ${env == 'prod'}
  confirmation_phrase: "deploy to production"
  require_clean_branch: ${env == 'prod'}
  allowed_branches: ${env == 'prod' ? '[main, release/*]' : '[]'}
  disallow_snapshot_versions: ${env == 'prod'}
''';
  }

  /// Patches specific fields in an env YAML file using regex substitution,
  /// preserving all other content and formatting.
  Future<void> updateEnvFields({
    required String projectId,
    required String envName,
    required Map<String, String> fields,
  }) async {
    final file = File(
        p.join(_projectDir(projectId), 'envs', '$envName.yaml'));
    if (!await file.exists()) return;
    var content = await file.readAsString();

    void patch(String yamlKey, String value) {
      if (value.isEmpty) return;
      final pattern = RegExp('($yamlKey:\\s*)(.*)', multiLine: true);
      if (pattern.hasMatch(content)) {
        content = content.replaceFirstMapped(pattern, (m) => '${m[1]}$value');
      } else {
        // Key missing (old YAML) — append at top level
        content = content.trimRight() + '\n$yamlKey: $value\n';
      }
    }

    patch('dart_define_from_file', fields['dart_define_from_file'] ?? '');

    // tester_groups: convert "group1, group2" → "[group1, group2]" for YAML
    final rawGroups = fields['firebase_tester_groups'] ?? '';
    if (rawGroups.isNotEmpty) {
      final groups = rawGroups
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .join(', ');
      patch('tester_groups', '[$groups]');
    }

    patch('package_name', fields['android_package_name'] ?? '');
    patch('firebase_app_id', fields['android_firebase_app_id'] ?? '');
    patch('bundle_id', fields['ios_bundle_id'] ?? '');
    patch('team_id', fields['ios_team_id'] ?? '');
    patch('export_method', fields['ios_export_method'] ?? '');
    patch('provisioning_profile', fields['ios_provisioning_profile'] ?? '');

    // Fields that appear in both android and ios sections need section-aware patching
    final iosSection = content.indexOf('\nios:');

    // ios firebase_app_id is the second occurrence — patch only within ios: block
    final iosFirebaseId = fields['ios_firebase_app_id'] ?? '';
    if (iosFirebaseId.isNotEmpty && iosSection != -1) {
      final iosBlock = content.substring(iosSection);
      final patched = iosBlock.replaceFirstMapped(
        RegExp(r'(firebase_app_id:\s*)(.*)', multiLine: true),
        (m) => '${m[1]}$iosFirebaseId',
      );
      content = content.substring(0, iosSection) + patched;
    }

    await file.writeAsString(content);
  }

  String _defaultPipelineYaml() => '''
name: mobile_build
description: "Full mobile build and distribution pipeline"

steps:
  - id: preflight
    type: preflight_check
    name: "Pre-flight Checks"
    abort_on_failure: true

  - id: checkout
    type: git_checkout
    name: "Checkout Repository"
    abort_on_failure: true

  - id: set_version
    type: set_version
    name: "Apply Version"
    abort_on_failure: true

  - id: install_deps
    type: flutter_pub_get
    name: "Install Dependencies"
    retry:
      max_attempts: 2
      delay_seconds: 5

  - id: build_android
    type: flutter_build
    name: "Build Android"
    condition: "android"
    params:
      platform: android
      artifact: apk
    abort_on_failure: true

  - id: build_ios
    type: flutter_build
    name: "Build iOS"
    condition: "ios"
    params:
      platform: ios
      artifact: ipa
    abort_on_failure: true

  - id: distribute_firebase_android
    type: firebase_distribute
    name: "Firebase (Android)"
    condition: "firebase_android"
    depends_on: [build_android]
    params:
      platform: android
    retry:
      max_attempts: 2
      delay_seconds: 10

  - id: archive_ios
    type: ios_archive
    name: "Archive & Sign iOS"
    condition: "ios"
    depends_on: [build_ios]
    abort_on_failure: true

  - id: distribute_firebase_ios
    type: firebase_distribute
    name: "Firebase (iOS)"
    condition: "firebase_ios"
    depends_on: [archive_ios]
    params:
      platform: ios

  - id: distribute_testflight
    type: fastlane_lane
    name: "TestFlight Upload"
    condition: "testflight"
    depends_on: [archive_ios]
    params:
      lane: upload_testflight

  - id: distribute_playstore
    type: fastlane_lane
    name: "Play Store Upload"
    condition: "playstore"
    depends_on: [build_android]
    params:
      lane: upload_playstore
''';
}

class ConfigNotFoundException implements Exception {
  final String message;
  const ConfigNotFoundException(this.message);
  @override
  String toString() => 'ConfigNotFoundException: $message';
}
