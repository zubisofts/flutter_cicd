import 'dart:io';
import 'package:path/path.dart' as p;
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

class SetVersionStep extends PipelineStep {
  final ProcessRunner _runner;

  SetVersionStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final version = ctx.environment.resolvedVersion;
    final buildNumber = ctx.environment.buildNumber;
    final dir = ctx.workspaceDir;

    ctx.logSink.addRaw(id, LogLevel.info,
        'Setting version to $version+$buildNumber');

    try {
      await _patchPubspec(dir, version, buildNumber, ctx);
      if (ctx.options.platforms.contains('android')) {
        await _patchAndroid(dir, version, buildNumber, ctx);
      }
      if (ctx.options.platforms.contains('ios')) {
        await _patchIos(dir, version, buildNumber, ctx);
      }
    } catch (e) {
      throw FatalPipelineException(
        stepId: id,
        message: 'Failed to apply version: $e',
      );
    }

    ctx.logSink.addRaw(
        id, LogLevel.success, 'Version set to $version+$buildNumber');
    return StepResult.success();
  }

  Future<void> _patchPubspec(
      String dir, String version, int buildNumber, PipelineContext ctx) async {
    final file = File(p.join(dir, 'pubspec.yaml'));
    if (!await file.exists()) return;
    var content = await file.readAsString();
    content = content.replaceFirstMapped(
      RegExp(r'^version:\s*.+$', multiLine: true),
      (_) => 'version: $version+$buildNumber',
    );
    await file.writeAsString(content);
    ctx.logSink.addRaw(
        id, LogLevel.debug, 'Patched pubspec.yaml');
  }

  Future<void> _patchAndroid(
      String dir, String version, int buildNumber, PipelineContext ctx) async {
    // Try build.gradle (Groovy DSL)
    final gradleFile = File(p.join(dir, 'android', 'app', 'build.gradle'));
    if (await gradleFile.exists()) {
      var content = await gradleFile.readAsString();
      content = content
          .replaceFirstMapped(
            RegExp(r'versionName\s+"[^"]*"'),
            (_) => 'versionName "$version"',
          )
          .replaceFirstMapped(
            RegExp(r'versionCode\s+\d+'),
            (_) => 'versionCode $buildNumber',
          );
      await gradleFile.writeAsString(content);
      ctx.logSink.addRaw(
          id, LogLevel.debug, 'Patched android/app/build.gradle');
      return;
    }

    // Try build.gradle.kts (Kotlin DSL)
    final ktsFile =
        File(p.join(dir, 'android', 'app', 'build.gradle.kts'));
    if (await ktsFile.exists()) {
      var content = await ktsFile.readAsString();
      content = content
          .replaceFirstMapped(
            RegExp(r'versionName\s*=\s*"[^"]*"'),
            (_) => 'versionName = "$version"',
          )
          .replaceFirstMapped(
            RegExp(r'versionCode\s*=\s*\d+'),
            (_) => 'versionCode = $buildNumber',
          );
      await ktsFile.writeAsString(content);
      ctx.logSink.addRaw(
          id, LogLevel.debug, 'Patched android/app/build.gradle.kts');
    }
  }

  Future<void> _patchIos(
      String dir, String version, int buildNumber, PipelineContext ctx) async {
    final iosDir = p.join(dir, 'ios');
    if (!await Directory(iosDir).exists()) return;

    // Use agvtool if available (requires xcodeproj-compatible directory)
    final agvResult = await _runner.run(
      command: ['agvtool', 'new-marketing-version', version],
      workingDir: iosDir,
      logSink: ctx.logSink,
      stepId: id,
    );

    if (agvResult.success) {
      await _runner.run(
        command: ['agvtool', 'new-version', '-all', '$buildNumber'],
        workingDir: iosDir,
        logSink: ctx.logSink,
        stepId: id,
      );
      ctx.logSink.addRaw(id, LogLevel.debug, 'Patched iOS version via agvtool');
    } else {
      // Fallback: patch Info.plist directly
      await _patchInfoPlist(iosDir, version, buildNumber, ctx);
    }
  }

  Future<void> _patchInfoPlist(String iosDir, String version,
      int buildNumber, PipelineContext ctx) async {
    // Find Info.plist
    final result = await _runner.run(
      command: ['find', iosDir, '-name', 'Info.plist', '-not', '-path', '*/Pods/*'],
      workingDir: iosDir,
      stepId: id,
    );

    for (final plistPath in result.output) {
      final path = plistPath.trim();
      if (path.isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;

      final plistResult = await _runner.run(
        command: [
          '/usr/libexec/PlistBuddy',
          '-c',
          'Set :CFBundleShortVersionString $version',
          path,
        ],
        workingDir: iosDir,
        stepId: id,
      );
      if (plistResult.success) {
        await _runner.run(
          command: [
            '/usr/libexec/PlistBuddy',
            '-c',
            'Set :CFBundleVersion $buildNumber',
            path,
          ],
          workingDir: iosDir,
          stepId: id,
        );
        ctx.logSink.addRaw(
            id, LogLevel.debug, 'Patched $path');
      }
    }
  }
}
