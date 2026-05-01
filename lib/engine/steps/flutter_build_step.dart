import 'dart:io';
import 'package:path/path.dart' as p;
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../config/models/resolved_environment.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

class FlutterBuildStep extends PipelineStep {
  final ProcessRunner _runner;

  FlutterBuildStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final platform = definition.params['platform'] as String;
    final artifact = definition.params['artifact'] as String? ?? 'apk';
    final env = ctx.environment;

    // iOS IPA is handled entirely by the ios_archive step (flutter build ipa).
    // Running flutter build ios here would double-compile the same project.
    if (platform == 'ios' && artifact == 'ipa') {
      ctx.logSink.addRaw(id, LogLevel.debug,
          'iOS IPA build delegated to Archive & Sign step — skipping.');
      return StepResult.success();
    }

    ctx.logSink.addRaw(id, LogLevel.info, 'Building $platform ($artifact)...');

    if (platform == 'android') {
      await _prepareAndroidSigning(ctx);
    }

    final command = _buildCommand(platform, artifact, ctx);
    final shellEnv = _buildShellEnv(platform, env);

    final result = await _runner.run(
      command: command,
      workingDir: ctx.workspaceDir,
      environment: shellEnv,
      timeout: const Duration(minutes: 45),
      logSink: ctx.logSink,
      stepId: id,
    );

    if (!result.success) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Flutter build $platform failed (exit ${result.exitCode})',
        exitCode: result.exitCode,
      );
    }

    // Flavor: use explicit YAML value if set, otherwise fall back to env name
    final rawFlavor = platform == 'android'
        ? ctx.environment.androidFlavor
        : ctx.environment.iosFlavor;
    final flavor = rawFlavor.isNotEmpty ? rawFlavor : ctx.environment.name;
    final artifactPath =
        _resolveArtifactPath(ctx.workspaceDir, platform, artifact, flavor: flavor);
    if (artifactPath != null) {
      ctx.putArtifact(platform, artifactPath);
      ctx.logSink.addRaw(id, LogLevel.success, 'Artifact: $artifactPath');
    }

    return StepResult.success(metadata: {'artifact_path': artifactPath ?? ''});
  }

  /// Writes android/key.properties so the Gradle signing block can read it,
  /// and sets CI=true so repos that detect CI via env var use the env-var path.
  Future<void> _prepareAndroidSigning(PipelineContext ctx) async {
    final signing = ctx.environment.androidSigning;
    final shellEnv = ctx.environment.shellEnv;

    // Resolve actual secret values from the shell env map
    final keystorePassword = shellEnv['KEYSTORE_PASSWORD'] ?? '';
    final keyPassword = shellEnv['KEY_PASSWORD'] ?? '';
    final keystorePath = _expandHome(signing.keystore);

    if (keystorePath.isEmpty || signing.keyAlias.isEmpty) {
      ctx.logSink.addRaw(id, LogLevel.warning,
          'Android signing not configured — building with debug signing. '
          'Set keystore/key_alias in your env YAML to sign for release.');
      // Patch buildTypes to use debugSigningConfig for release so the build
      // doesn't crash on missing key.properties
      await _patchGradleToDebugSigning(ctx.workspaceDir, ctx);
      return;
    }

    // Write key.properties for repos that use the local-signing path
    final keyPropsFile =
        File(p.join(ctx.workspaceDir, 'android', 'key.properties'));
    await keyPropsFile.writeAsString(
      'storePassword=$keystorePassword\n'
      'keyPassword=$keyPassword\n'
      'keyAlias=${signing.keyAlias}\n'
      'storeFile=$keystorePath\n',
    );

    ctx.logSink.addRaw(id, LogLevel.debug,
        'Wrote android/key.properties (keystore: $keystorePath)');
  }

  /// If no signing is configured, patch build.gradle / build.gradle.kts to
  /// use debug signing for the release build type so Gradle doesn't crash.
  Future<void> _patchGradleToDebugSigning(
      String workspaceDir, PipelineContext ctx) async {
    // Kotlin DSL
    final kts = File(p.join(workspaceDir, 'android', 'app', 'build.gradle.kts'));
    if (await kts.exists()) {
      var content = await kts.readAsString();
      // Replace `signingConfig = signingConfigs.getByName("release")` with debug
      content = content.replaceAll(
        RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\("release"\)'),
        'signingConfig = signingConfigs.getByName("debug")',
      );
      // Also wrap the whole signingConfigs block to avoid the null cast crash
      // by replacing `as String` with `as? String ?: ""`
      content = content.replaceAll(
        RegExp(r'as String\b'),
        'as? String ?: ""',
      );
      await kts.writeAsString(content);
      ctx.logSink.addRaw(id, LogLevel.debug,
          'Patched build.gradle.kts to use debug signing');
      return;
    }

    // Groovy DSL
    final groovy =
        File(p.join(workspaceDir, 'android', 'app', 'build.gradle'));
    if (await groovy.exists()) {
      var content = await groovy.readAsString();
      content = content.replaceAll(
        RegExp(r"signingConfig\s*=?\s*signingConfigs\.release\b"),
        'signingConfig signingConfigs.debug',
      );
      await groovy.writeAsString(content);
      ctx.logSink.addRaw(
          id, LogLevel.debug, 'Patched build.gradle to use debug signing');
    }
  }

  List<String> _buildCommand(
      String platform, String artifact, PipelineContext ctx) {
    final env = ctx.environment;
    final useDefineFromFile = env.dartDefineFromFile.isNotEmpty;
    final androidFlavor =
        env.androidFlavor.isNotEmpty ? env.androidFlavor : env.name;
    final iosFlavor =
        env.iosFlavor.isNotEmpty ? env.iosFlavor : env.name;

    switch (platform) {
      case 'android':
        return [
          'flutter',
          'build',
          artifact, // apk | appbundle
          '--release',
          '--build-name=${env.resolvedVersion}',
          '--build-number=${env.buildNumber}',
          '--flavor=$androidFlavor',
          if (useDefineFromFile)
            '--dart-define-from-file=${env.dartDefineFromFile}'
          else ...[
            '--dart-define=ENV=${env.name}',
            if (env.androidPackageName.isNotEmpty)
              '--dart-define=PACKAGE_NAME=${env.androidPackageName}',
          ],
        ];
      case 'ios':
        return [
          'flutter',
          'build',
          'ios',
          '--release',
          '--no-codesign',
          '--build-name=${env.resolvedVersion}',
          '--build-number=${env.buildNumber}',
          '--flavor=$iosFlavor',
          if (useDefineFromFile)
            '--dart-define-from-file=${env.dartDefineFromFile}'
          else ...[
            '--dart-define=ENV=${env.name}',
            if (env.iosBundleId.isNotEmpty)
              '--dart-define=BUNDLE_ID=${env.iosBundleId}',
          ],
        ];
      default:
        throw FatalPipelineException(
          stepId: id,
          message: 'Unknown platform: $platform',
        );
    }
  }

  Map<String, String> _buildShellEnv(String platform, ResolvedEnvironment env) {
    final base = {...env.shellEnv};
    if (platform == 'android') {
      // Always set CI=true so repos that check for CI use the env-var signing
      // path rather than the key.properties path (avoids null-cast crashes when
      // key.properties is absent).
      base['CI'] = 'true';

      final signing = env.androidSigning;
      final keystorePath = _expandHome(signing.keystore);

      // Codemagic-compatible variable names (common in Flutter repos)
      if (keystorePath.isNotEmpty) {
        base['CM_KEYSTORE_PATH'] = keystorePath;
        base['CM_KEY_ALIAS'] = signing.keyAlias;
        base['CM_KEYSTORE_PASSWORD'] = base['KEYSTORE_PASSWORD'] ?? '';
        base['CM_KEY_PASSWORD'] = base['KEY_PASSWORD'] ?? '';
      }

      // Generic aliases used by various templates
      base['KEYSTORE_PATH'] = keystorePath;
      base['KEY_ALIAS'] = signing.keyAlias;
    }
    return base;
  }

  String? _resolveArtifactPath(
      String workspaceDir, String platform, String artifact,
      {String flavor = ''}) {
    switch (platform) {
      case 'android':
        if (artifact == 'apk') {
          final apkDir = p.join(
              workspaceDir, 'build', 'app', 'outputs', 'flutter-apk');
          // Flavored build: app-{flavor}-release.apk
          if (flavor.isNotEmpty) {
            final flavored = p.join(apkDir, 'app-$flavor-release.apk');
            if (File(flavored).existsSync()) return flavored;
          }
          // Standard: app-release.apk
          final standard = p.join(apkDir, 'app-release.apk');
          if (File(standard).existsSync()) return standard;
          // Glob fallback: any *-release.apk in the dir
          final dir = Directory(apkDir);
          if (dir.existsSync()) {
            final match = dir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('-release.apk'))
                .firstOrNull;
            if (match != null) return match.path;
          }
          return null;
        }
        // AAB
        if (flavor.isNotEmpty) {
          final flavored = p.join(workspaceDir, 'build', 'app', 'outputs',
              'bundle', '${flavor}Release', 'app-$flavor-release.aab');
          if (File(flavored).existsSync()) return flavored;
        }
        return p.join(workspaceDir, 'build', 'app', 'outputs',
            'bundle', 'release', 'app-release.aab');
      case 'ios':
        final flavor_ = flavor.isNotEmpty ? flavor : 'Runner';
        final withFlavor =
            p.join(workspaceDir, 'build', 'ios', 'iphoneos', '$flavor_.app');
        if (File(withFlavor).existsSync()) return withFlavor;
        return p.join(workspaceDir, 'build', 'ios', 'iphoneos', 'Runner.app');
      default:
        return null;
    }
  }

  String _expandHome(String path) {
    if (path.startsWith('~/')) {
      return p.join(
          Platform.environment['HOME'] ?? '', path.substring(2));
    }
    return path;
  }
}
