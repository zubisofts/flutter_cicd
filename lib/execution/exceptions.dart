class FatalPipelineException implements Exception {
  final String stepId;
  final String message;
  final int? exitCode;

  const FatalPipelineException({
    required this.stepId,
    required this.message,
    this.exitCode,
  });

  @override
  String toString() =>
      'FatalPipelineException[$stepId]: $message'
      '${exitCode != null ? ' (exit $exitCode)' : ''}';
}

class RetryableStepException implements Exception {
  final String stepId;
  final String message;

  const RetryableStepException({
    required this.stepId,
    required this.message,
  });

  @override
  String toString() => 'RetryableStepException[$stepId]: $message';
}

class StepSkippedException implements Exception {
  final String stepId;
  final String reason;
  const StepSkippedException(this.stepId, this.reason);
  @override
  String toString() => 'StepSkipped[$stepId]: $reason';
}

class PipelineAbortedException implements Exception {
  const PipelineAbortedException();
  @override
  String toString() => 'Pipeline was aborted by user';
}
