enum StepStatus { pending, running, success, failed, skipped, aborted }

class StepResult {
  final StepStatus status;
  final String? errorMessage;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  const StepResult._({
    required this.status,
    this.errorMessage,
    this.duration,
    this.metadata = const {},
  });

  factory StepResult.success({
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) =>
      StepResult._(
          status: StepStatus.success,
          duration: duration,
          metadata: metadata);

  factory StepResult.failed(String message, {Duration? duration}) =>
      StepResult._(
          status: StepStatus.failed,
          errorMessage: message,
          duration: duration);

  factory StepResult.skipped(String reason) =>
      StepResult._(status: StepStatus.skipped, errorMessage: reason);

  factory StepResult.aborted() =>
      const StepResult._(status: StepStatus.aborted);

  bool get isSuccess => status == StepStatus.success;
  bool get isFailed => status == StepStatus.failed;
  bool get isSkipped => status == StepStatus.skipped;
}
