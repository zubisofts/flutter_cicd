import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../config/models/app_project.dart';
import '../../di/injection.dart';
import '../../config/config_repository.dart';
import '../../engine/build_queue.dart';
import '../dialogs/production_confirm_dialog.dart';
import '../dialogs/new_project_dialog.dart';
import 'setup_bloc.dart';
import 'widgets/env_selector.dart';
import 'widgets/platform_target_selector.dart';
import 'widgets/section_card.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SetupBloc(getIt<ConfigRepository>())..add(const SetupInitialized()),
      child: const _SetupScreenContent(),
    );
  }
}

class _SetupScreenContent extends StatelessWidget {
  const _SetupScreenContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetupBloc, SetupState>(
      listenWhen: (prev, curr) => curr.readyToRun && !prev.readyToRun,
      listener: (context, state) {
        if (state.requiresProductionConfirm) {
          ProductionConfirmDialog.show(
            context,
            'deploy to production',
            () => _launchPipeline(context),
          );
        } else {
          _launchPipeline(context);
        }
        context.read<SetupBloc>().add(const ResetReadyToRun());
      },
      builder: (context, state) {
        return Scaffold(
          body: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(),
                      const Gap(20),
                      if (state.error != null) _ErrorBanner(state.error!),
                      _ProjectSection(state: state),
                      const Gap(12),
                      _BranchSection(state: state),
                      const Gap(12),
                      _EnvironmentSection(state: state),
                      const Gap(12),
                      _VersionSection(state: state),
                      const Gap(12),
                      _PlatformSection(state: state),
                      const Gap(12),
                      _TargetSection(state: state),
                      if (state.targets.contains('playstore')) ...[
                        const Gap(12),
                        _PlayStoreOptionsSection(state: state),
                      ],
                      const Gap(24),
                      _ActionBar(state: state),
                    ],
                  ),
                ),
              ),
              _VersionPreviewPanel(state: state),
            ],
          ),
        );
      },
    );
  }

  void _launchPipeline(BuildContext context) {
    final bloc = context.read<SetupBloc>();
    final request = bloc.buildRunRequest();
    getIt<BuildQueue>().submit(request);
    context.go('/queue');
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pipeline Setup',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(4),
        const Text(
          'Configure and launch your build pipeline',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner(this.error);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF85149).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(6),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFF85149))),
      ),
      child: Text(
        error,
        style: const TextStyle(color: Color(0xFFF85149), fontSize: 13),
      ),
    );
  }
}

class _ProjectSection extends StatelessWidget {
  final SetupState state;
  const _ProjectSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SetupBloc>();
    return SectionCard(
      title: 'PROJECT',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.selectedProject != null) ...[
            IconButton(
              onPressed: () => context.go('/settings', extra: {
                'projectId': state.selectedProject!.id,
                'env': state.selectedEnv,
              }),
              icon: const Icon(Icons.settings, size: 16),
              tooltip: 'Configure',
              color: const Color(0xFF8B949E),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            IconButton(
              onPressed: () => _confirmDeleteProject(
                  context, bloc, state.selectedProject!),
              icon: const Icon(Icons.delete_outline, size: 16),
              tooltip: 'Delete project',
              color: const Color(0xFFF85149),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
          IconButton(
            onPressed: () async {
              final result = await NewProjectDialog.show(context);
              if (result != null) {
                bloc.add(NewProjectRequested(
                    result.id, result.name, result.repo));
              }
            },
            icon: const Icon(Icons.add, size: 16),
            tooltip: 'New Project',
            color: const Color(0xFF58A6FF),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.projects.isEmpty
              ? _EmptyProjects()
              : DropdownButtonFormField<String>(
                  initialValue: state.selectedProject?.id,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface),
                  items: state.projects
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ))
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      final project = state.projects
                          .firstWhere((p) => p.id == id);
                      bloc.add(ProjectSelected(project));
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Project',
                  ),
                ),
    );
  }
}

Future<void> _confirmDeleteProject(
    BuildContext context, SetupBloc bloc, AppProject project) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Project'),
      content: Text(
        'Delete "${project.name}"?\n\nThis removes all config, env files and bundled assets. '
        'It cannot be undone.',
        style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF85149)),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    bloc.add(ProjectDeleted(project.id));
  }
}

class _EmptyProjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Column(
        children: const [
          Icon(Icons.folder_open, color: Color(0xFF8B949E), size: 32),
          Gap(8),
          Text(
            'No projects found',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
          Gap(4),
          Text(
            'Click "New Project" to add your first project',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BranchSection extends StatelessWidget {
  final SetupState state;
  const _BranchSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SetupBloc>();
    return SectionCard(
      title: 'BRANCH / TAG',
      trailing: state.isFetchingBranches
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : IconButton(
              icon: const Icon(Icons.refresh, size: 14),
              tooltip: 'Refresh',
              color: const Color(0xFF8B949E),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: state.selectedProject == null
                  ? null
                  : () => bloc.add(ProjectSelected(state.selectedProject!)),
            ),
      child: _BranchAutocomplete(state: state),
    );
  }
}

class _BranchAutocomplete extends StatefulWidget {
  final SetupState state;
  const _BranchAutocomplete({required this.state});

  @override
  State<_BranchAutocomplete> createState() => _BranchAutocompleteState();
}

class _BranchAutocompleteState extends State<_BranchAutocomplete> {
  late TextEditingController _ctrl;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.state.branch);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_BranchAutocomplete old) {
    super.didUpdateWidget(old);
    if (widget.state.branch != old.state.branch &&
        widget.state.branch != _ctrl.text) {
      _ctrl.text = widget.state.branch;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_GitRef> get _allRefs => [
        ...widget.state.branches.map((b) => _GitRef(b, isTag: false)),
        ...widget.state.tags.map((t) => _GitRef(t, isTag: true)),
      ];

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SetupBloc>();
    final refsLoaded = widget.state.branches.isNotEmpty ||
        widget.state.tags.isNotEmpty;
    final isInvalid = refsLoaded && !widget.state.branchValid &&
        widget.state.branch.isNotEmpty;

    return RawAutocomplete<_GitRef>(
      textEditingController: _ctrl,
      focusNode: _focusNode,
      optionsBuilder: (textValue) {
        final query = textValue.text.toLowerCase();
        if (query.isEmpty) return _allRefs;
        return _allRefs
            .where((r) => r.name.toLowerCase().contains(query));
      },
      onSelected: (ref) {
        _ctrl.text = ref.name;
        bloc.add(BranchChanged(ref.name));
      },
      fieldViewBuilder: (context, ctrl, focusNode, onSubmit) {
        return TextField(
          controller: ctrl,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: refsLoaded ? 'Branch or tag' : 'Branch name',
            hintText: 'main',
            prefixIcon: const Icon(Icons.call_split,
                size: 16, color: Color(0xFF8B949E)),
            suffixIcon: isInvalid
                ? const Tooltip(
                    message: 'Not found in remote refs',
                    child: Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFF0A500)),
                  )
                : null,
            errorText: isInvalid ? 'Not a known branch or tag' : null,
          ),
          onChanged: (v) => bloc.add(BranchChanged(v)),
          onSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 4,
            borderRadius: BorderRadius.circular(6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 340),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final ref = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            ref.isTag
                                ? Icons.sell_outlined
                                : Icons.call_split,
                            size: 13,
                            color: ref.isTag
                                ? const Color(0xFF3FB950)
                                : const Color(0xFF58A6FF),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ref.name,
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ref.isTag)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3FB950)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'tag',
                                style: TextStyle(
                                  color: Color(0xFF3FB950),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GitRef {
  final String name;
  final bool isTag;
  const _GitRef(this.name, {required this.isTag});
  @override
  String toString() => name;
}

class _EnvironmentSection extends StatelessWidget {
  final SetupState state;
  const _EnvironmentSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'ENVIRONMENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnvSelector(
            environments: state.availableEnvs,
            selected: state.selectedEnv,
            onSelected: (env) =>
                context.read<SetupBloc>().add(EnvSelected(env)),
          ),
          if (state.selectedEnv == 'prod') ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF85149).withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(6),
                border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFFF85149), width: 0.5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF85149), size: 16),
                  Gap(8),
                  Expanded(
                    child: Text(
                      'Production environment selected. '
                      'You will be asked to confirm before the pipeline runs.',
                      style: TextStyle(
                          color: Color(0xFFF85149), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersionSection extends StatefulWidget {
  final SetupState state;
  const _VersionSection({required this.state});

  @override
  State<_VersionSection> createState() => _VersionSectionState();
}

class _VersionSectionState extends State<_VersionSection> {
  late final TextEditingController _versionCtrl;
  late final TextEditingController _buildCtrl;

  @override
  void initState() {
    super.initState();
    _versionCtrl =
        TextEditingController(text: widget.state.versionName);
    _buildCtrl =
        TextEditingController(text: widget.state.buildNumber);
  }

  @override
  void didUpdateWidget(_VersionSection old) {
    super.didUpdateWidget(old);
    if (widget.state.versionName != old.state.versionName &&
        widget.state.versionName != _versionCtrl.text) {
      _versionCtrl.text = widget.state.versionName;
    }
    if (widget.state.buildNumber != old.state.buildNumber &&
        widget.state.buildNumber != _buildCtrl.text) {
      _buildCtrl.text = widget.state.buildNumber;
    }
  }

  @override
  void dispose() {
    _versionCtrl.dispose();
    _buildCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SetupBloc>();
    return SectionCard(
      title: 'VERSION',
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _versionCtrl,
              style: const TextStyle(
                  fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Version name',
                hintText: '1.0.0',
              ),
              onChanged: (v) => bloc.add(VersionNameChanged(v)),
            ),
          ),
          const Gap(12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _buildCtrl,
              style: const TextStyle(
                  fontSize: 13),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Build number',
                hintText: '1',
              ),
              onChanged: (v) => bloc.add(BuildNumberChanged(v)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformSection extends StatelessWidget {
  final SetupState state;
  const _PlatformSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PLATFORMS',
      child: PlatformSelector(
        selected: state.platforms,
        onToggle: (p) =>
            context.read<SetupBloc>().add(PlatformToggled(p)),
      ),
    );
  }
}

class _TargetSection extends StatelessWidget {
  final SetupState state;
  const _TargetSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'DISTRIBUTION TARGETS',
      child: TargetSelector(
        selected: state.targets,
        onToggle: (t) =>
            context.read<SetupBloc>().add(TargetToggled(t)),
      ),
    );
  }
}

class _PlayStoreOptionsSection extends StatefulWidget {
  final SetupState state;
  const _PlayStoreOptionsSection({required this.state});

  @override
  State<_PlayStoreOptionsSection> createState() =>
      _PlayStoreOptionsSectionState();
}

class _PlayStoreOptionsSectionState extends State<_PlayStoreOptionsSection> {
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.state.releaseNotes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SetupBloc>();
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      title: 'PLAY STORE OPTIONS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Release notes (optional)',
              hintText: "What's new in this release?",
              alignLabelWithHint: true,
            ),
            onChanged: (v) => bloc.add(ReleaseNotesChanged(v)),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Managed publishing',
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                    const Gap(2),
                    Text(
                      'Upload as draft — publish manually from the Play Console',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.state.managedPublishing,
                onChanged: (_) =>
                    bloc.add(const ManagedPublishingToggled()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final SetupState state;
  const _ActionBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        ElevatedButton.icon(
          onPressed: state.isValid
              ? () => context
                  .read<SetupBloc>()
                  .add(const RunPipelineRequested())
              : null,
          icon: const Icon(Icons.rocket_launch, size: 16),
          label: Text(
            state.selectedEnv == 'prod'
                ? 'DEPLOY TO PRODUCTION'
                : 'START PIPELINE',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: state.selectedEnv == 'prod'
                ? const Color(0xFFF85149)
                : const Color(0xFF58A6FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _VersionPreviewPanel extends StatelessWidget {
  final SetupState state;
  const _VersionPreviewPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PREVIEW',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(16),
          _PreviewItem(label: 'Project',
              value: state.selectedProject?.name ?? '—'),
          _PreviewItem(label: 'Branch', value: state.branch),
          _PreviewItem(label: 'Environment',
              value: state.selectedEnv.toUpperCase()),
          _PreviewItem(label: 'Version', value: state.versionPreview),
          _PreviewItem(
              label: 'Platforms',
              value: state.platforms.join(', ')),
          _PreviewItem(
              label: 'Targets',
              value: state.targets.isEmpty ? '—' : state.targets.join(', ')),
          const Divider(height: 24),
          if (state.selectedEnv == 'prod')
            const _ProdWarning()
          else
            const _ReadyIndicator(),
        ],
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String label;
  final String value;
  const _PreviewItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8B949E), fontSize: 11)),
          const Gap(2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProdWarning extends StatelessWidget {
  const _ProdWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF85149).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock, size: 14, color: Color(0xFFF85149)),
          Gap(6),
          Expanded(
            child: Text(
              'Confirmation required',
              style:
                  TextStyle(color: Color(0xFFF85149), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyIndicator extends StatelessWidget {
  const _ReadyIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3FB950).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 14, color: Color(0xFF3FB950)),
          Gap(6),
          Expanded(
            child: Text(
              'Ready to launch',
              style:
                  TextStyle(color: Color(0xFF3FB950), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
