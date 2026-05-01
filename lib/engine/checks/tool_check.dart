import '../../execution/process_runner.dart';

enum CheckStatus { ok, warning, fatal }

class CheckResult {
  final String name;
  final CheckStatus status;
  final String? version;
  final String? message;

  const CheckResult._({
    required this.name,
    required this.status,
    this.version,
    this.message,
  });

  factory CheckResult.ok(String name, String? version) =>
      CheckResult._(name: name, status: CheckStatus.ok, version: version);

  factory CheckResult.warning(String name, String message) =>
      CheckResult._(
          name: name, status: CheckStatus.warning, message: message);

  factory CheckResult.fatal(String name, String message) =>
      CheckResult._(
          name: name, status: CheckStatus.fatal, message: message);

  bool get isOk => status == CheckStatus.ok;
  bool get isFatal => status == CheckStatus.fatal;

  String get label {
    switch (status) {
      case CheckStatus.ok:
        return version != null ? '$name $version' : name;
      case CheckStatus.warning:
        return '$name: $message';
      case CheckStatus.fatal:
        return '$name: NOT FOUND — $message';
    }
  }
}

abstract class ToolCheck {
  String get name;
  List<String> get checkCommand;
  String? extractVersion(String output);

  bool isRequired(List<String> platforms, List<String> targets) => true;

  Future<CheckResult> run() async {
    try {
      final runner = ProcessRunner();
      final result = await runner.run(
        command: checkCommand,
        workingDir: '/tmp',
        timeout: const Duration(seconds: 15),
      );
      if (result.success || result.output.isNotEmpty) {
        final version = extractVersion(result.output.join('\n'));
        return CheckResult.ok(name, version);
      }
      return CheckResult.fatal(name, 'Command returned non-zero exit code');
    } catch (e) {
      return CheckResult.fatal(name, 'Not found in PATH: $e');
    }
  }
}

class FlutterCheck extends ToolCheck {
  @override
  String get name => 'Flutter';
  @override
  List<String> get checkCommand => ['flutter', '--version', '--machine'];
  @override
  String? extractVersion(String output) {
    final match = RegExp(r'"frameworkVersion":"([^"]+)"').firstMatch(output);
    return match?.group(1);
  }
}

class XcodeCheck extends ToolCheck {
  final List<String> platforms;
  XcodeCheck(this.platforms);

  @override
  String get name => 'Xcode';
  @override
  List<String> get checkCommand => ['xcodebuild', '-version'];
  @override
  bool isRequired(List<String> platforms, List<String> targets) =>
      platforms.contains('ios');
  @override
  String? extractVersion(String output) =>
      RegExp(r'Xcode (\S+)').firstMatch(output)?.group(1);
}

class FastlaneCheck extends ToolCheck {
  @override
  String get name => 'Fastlane';
  @override
  List<String> get checkCommand =>
      ['bundle', 'exec', 'fastlane', '--version'];
  @override
  String? extractVersion(String output) =>
      RegExp(r'fastlane (\S+)').firstMatch(output)?.group(1);
}

class FirebaseCliCheck extends ToolCheck {
  @override
  String get name => 'Firebase CLI';
  @override
  List<String> get checkCommand => ['firebase', '--version'];
  @override
  String? extractVersion(String output) =>
      RegExp(r'(\d+\.\d+\.\d+)').firstMatch(output)?.group(1);
}

class CocoaPodsCheck extends ToolCheck {
  @override
  String get name => 'CocoaPods';
  @override
  List<String> get checkCommand => ['pod', '--version'];
  @override
  bool isRequired(List<String> platforms, List<String> targets) =>
      platforms.contains('ios');
  @override
  String? extractVersion(String output) =>
      RegExp(r'(\d+\.\d+\.\d+)').firstMatch(output)?.group(1);
}

class GitCheck extends ToolCheck {
  @override
  String get name => 'Git';
  @override
  List<String> get checkCommand => ['git', '--version'];
  @override
  String? extractVersion(String output) =>
      RegExp(r'git version (\S+)').firstMatch(output)?.group(1);
}

class JavaCheck extends ToolCheck {
  @override
  String get name => 'Java';
  @override
  List<String> get checkCommand => ['java', '-version'];
  @override
  bool isRequired(List<String> platforms, List<String> targets) =>
      platforms.contains('android');
  @override
  String? extractVersion(String output) =>
      RegExp(r'"(\d+[^"]*)"').firstMatch(output)?.group(1);
}
