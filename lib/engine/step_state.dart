import 'package:equatable/equatable.dart';
import 'step_result.dart';

class PipelineStepState extends Equatable {
  final String stepId;
  final String stepName;
  final StepStatus status;
  final Duration? duration;
  final String? errorMessage;

  const PipelineStepState({
    required this.stepId,
    required this.stepName,
    required this.status,
    this.duration,
    this.errorMessage,
  });

  PipelineStepState copyWith({
    StepStatus? status,
    Duration? duration,
    String? errorMessage,
  }) =>
      PipelineStepState(
        stepId: stepId,
        stepName: stepName,
        status: status ?? this.status,
        duration: duration ?? this.duration,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [stepId, stepName, status, duration, errorMessage];
}
