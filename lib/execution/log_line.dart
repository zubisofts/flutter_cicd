enum LogLevel { debug, info, warning, error, success }

class LogLine {
  final String stepId;
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  const LogLine({
    required this.stepId,
    required this.level,
    required this.message,
    required this.timestamp,
  });

  String get levelLabel {
    switch (level) {
      case LogLevel.debug:
        return 'DBG';
      case LogLevel.info:
        return 'INF';
      case LogLevel.warning:
        return 'WRN';
      case LogLevel.error:
        return 'ERR';
      case LogLevel.success:
        return 'OK ';
    }
  }

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] [$levelLabel] [$stepId] $message';
}
