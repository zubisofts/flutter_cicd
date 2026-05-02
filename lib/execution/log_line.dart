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

  // Parses the format written by LogSink: [iso8601] [LVL] [stepId] message
  static LogLine fromLogFile(String raw) {
    final tsMatch = RegExp(r'^\[([^\]]+)\]').firstMatch(raw);
    final ts = tsMatch != null
        ? DateTime.tryParse(tsMatch.group(1)!) ?? DateTime.now()
        : DateTime.now();

    final lvlMatch = RegExp(r'^\[[^\]]+\] \[([A-Z ]+)\]').firstMatch(raw);
    final lvlLabel = lvlMatch?.group(1)?.trim() ?? 'INF';
    final level = switch (lvlLabel) {
      'ERR' => LogLevel.error,
      'WRN' => LogLevel.warning,
      'OK' => LogLevel.success,
      'DBG' => LogLevel.debug,
      _ => LogLevel.info,
    };

    final stepMatch =
        RegExp(r'^\[[^\]]+\] \[[^\]]+\] \[([^\]]*)\] (.*)$', dotAll: true)
            .firstMatch(raw);
    final stepId = stepMatch?.group(1) ?? '';
    final message = stepMatch?.group(2) ?? raw;

    return LogLine(stepId: stepId, level: level, message: message, timestamp: ts);
  }

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
