import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../engine/step_result.dart';
import '../../shell/app_theme.dart';
import '../execution_bloc.dart';

class StepProgressList extends StatelessWidget {
  final List<PipelineStepState> steps;

  const StepProgressList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(children: steps.map((s) => _StepRow(step: s)).toList());
  }
}

class _StepRow extends StatelessWidget {
  final PipelineStepState step;

  const _StepRow({required this.step});

  Widget _statusIcon(BuildContext context) {
    switch (step.status) {
      case StepStatus.success:
        return const Icon(
          Icons.check_circle,
          size: 16,
          color: AppTheme.colorSuccess,
        );
      case StepStatus.failed:
        return const Icon(Icons.cancel, size: 16, color: AppTheme.colorError);
      case StepStatus.running:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.colorRunning,
          ),
        );
      case StepStatus.skipped:
        return const Icon(
          Icons.skip_next,
          size: 16,
          color: AppTheme.colorSkipped,
        );
      case StepStatus.aborted:
        return const Icon(
          Icons.stop_circle,
          size: 16,
          color: AppTheme.colorWarning,
        );
      case StepStatus.pending:
        return Icon(
          Icons.radio_button_unchecked,
          size: 16,
          color: Theme.brightnessOf(context) == Brightness.dark
              ? AppTheme.colorPending
              : const Color(0xFFCACACA),
        );
    }
  }

  String get _durationLabel {
    if (step.duration == null) return '';
    final d = step.duration!;
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    if (d.inSeconds > 0) return '${d.inSeconds}s';
    return '< 1s';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = step.status == StepStatus.running;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isRunning
            ? AppTheme.colorRunning.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isRunning
              ? AppTheme.colorRunning.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          _statusIcon(context),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.stepName,
                  style: TextStyle(
                    color: step.status == StepStatus.pending
                        ? const Color(0xFF8B949E)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: isRunning ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (step.errorMessage != null)
                  Text(
                    step.errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.colorError,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_durationLabel.isNotEmpty)
            Text(
              _durationLabel,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
        ],
      ),
    );
  }
}
