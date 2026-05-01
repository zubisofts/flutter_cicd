import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../config/config_repository.dart';
import '../../di/injection.dart';
import '../../services/credential_store.dart';
import '../shell/app_theme.dart';
import '../setup/widgets/env_selector.dart';
import '../setup/widgets/section_card.dart';
import 'settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  final String projectId;
  final String initialEnv;

  const SettingsScreen({
    super.key,
    required this.projectId,
    required this.initialEnv,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc(
        getIt<CredentialStore>(),
        getIt<ConfigRepository>(),
      )..add(SettingsOpened(projectId, initialEnv)),
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(state: state),
                    const Divider(height: 1),
                    if (state.savedMessage != null)
                      _SavedBanner(state.savedMessage!),
                    if (state.error != null)
                      _ErrorBanner(state.error!),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _AndroidSigningCard(state: state),
                                  const Gap(12),
                                  _AppleCard(state: state),
                                  const Gap(12),
                                  _FirebaseCard(state: state),
                                ],
                              ),
                            ),
                            const Gap(20),
                            SizedBox(
                              width: 300,
                              child: Column(
                                children: [
                                  _EnvConfigCard(state: state),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final SettingsState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Settings',
            style: TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(4),
          Text(
            state.projectId,
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          ),
          const Gap(14),
          EnvSelector(
            environments: state.availableEnvs,
            selected: state.selectedEnv,
            onSelected: (env) =>
                context.read<SettingsBloc>().add(SettingsEnvChanged(env)),
          ),
        ],
      ),
    );
  }
}

// ─── Android Signing ──────────────────────────────────────────────────────

class _AndroidSigningCard extends StatefulWidget {
  final SettingsState state;
  const _AndroidSigningCard({required this.state});

  @override
  State<_AndroidSigningCard> createState() => _AndroidSigningCardState();
}

class _AndroidSigningCardState extends State<_AndroidSigningCard> {
  late TextEditingController _pathCtrl;
  late TextEditingController _aliasCtrl;
  late TextEditingController _ksPassCtrl;
  late TextEditingController _keyPassCtrl;
  bool _showKsPass = false;
  bool _showKeyPass = false;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.state);
  }

  @override
  void didUpdateWidget(_AndroidSigningCard old) {
    super.didUpdateWidget(old);
    if (old.state.selectedEnv != widget.state.selectedEnv ||
        old.state.projectId != widget.state.projectId) {
      _initControllers(widget.state);
    }
  }

  void _initControllers(SettingsState s) {
    _pathCtrl =
        TextEditingController(text: s.androidCreds.keystorePath);
    _aliasCtrl =
        TextEditingController(text: s.androidCreds.keyAlias);
    _ksPassCtrl =
        TextEditingController(text: s.androidCreds.keystorePassword);
    _keyPassCtrl =
        TextEditingController(text: s.androidCreds.keyPassword);
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    _aliasCtrl.dispose();
    _ksPassCtrl.dispose();
    _keyPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickKeystore() async {
    const typeGroup = XTypeGroup(
      label: 'Keystore',
      extensions: ['keystore', 'jks'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null && mounted) {
      final bundled = await getIt<ConfigRepository>()
          .bundleFile(widget.state.projectId, file.path);
      setState(() => _pathCtrl.text = bundled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = widget.state.androidCreds.isConfigured;
    return SectionCard(
      title: 'ANDROID SIGNING',
      trailing: isConfigured
          ? const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock, size: 12, color: AppTheme.colorSuccess),
              Gap(4),
              Text('Keychain',
                  style: TextStyle(
                      color: AppTheme.colorSuccess, fontSize: 11)),
            ])
          : const Text('Not configured',
              style: TextStyle(
                  color: Color(0xFF8B949E), fontSize: 11)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keystore file
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathCtrl,
                  readOnly: true,
                  style: const TextStyle(
                      color: Color(0xFFE6EDF3), fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Keystore file',
                    hintText: 'Select a .keystore or .jks file',
                    prefixIcon: Icon(Icons.folder_open,
                        size: 16, color: Color(0xFF8B949E)),
                  ),
                ),
              ),
              const Gap(8),
              OutlinedButton(
                onPressed: _pickKeystore,
                child: const Text('Browse'),
              ),
            ],
          ),
          const Gap(10),
          // Key alias
          TextField(
            controller: _aliasCtrl,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: const InputDecoration(labelText: 'Key alias'),
          ),
          const Gap(10),
          // Keystore password
          TextField(
            controller: _ksPassCtrl,
            obscureText: !_showKsPass,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Keystore password',
              suffixIcon: IconButton(
                icon: Icon(
                    _showKsPass
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                    color: const Color(0xFF8B949E)),
                onPressed: () =>
                    setState(() => _showKsPass = !_showKsPass),
              ),
            ),
          ),
          const Gap(10),
          // Key password
          TextField(
            controller: _keyPassCtrl,
            obscureText: !_showKeyPass,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Key password',
              suffixIcon: IconButton(
                icon: Icon(
                    _showKeyPass
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                    color: const Color(0xFF8B949E)),
                onPressed: () =>
                    setState(() => _showKeyPass = !_showKeyPass),
              ),
            ),
          ),
          const Gap(14),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 13, color: Color(0xFF8B949E)),
              const Gap(6),
              const Expanded(
                child: Text(
                  'Passwords are stored in macOS Keychain, never on disk.',
                  style: TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11),
                ),
              ),
            ],
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<SettingsBloc>().add(AndroidSigningSaved(
                      keystorePath: _pathCtrl.text.trim(),
                      keyAlias: _aliasCtrl.text.trim(),
                      keystorePassword: _ksPassCtrl.text,
                      keyPassword: _keyPassCtrl.text,
                    ));
              },
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save to Keychain'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Apple / TestFlight ───────────────────────────────────────────────────

class _AppleCard extends StatefulWidget {
  final SettingsState state;
  const _AppleCard({required this.state});

  @override
  State<_AppleCard> createState() => _AppleCardState();
}

class _AppleCardState extends State<_AppleCard> {
  late TextEditingController _appleIdCtrl;
  late TextEditingController _passCtrl;
  bool _showPass = false;

  @override
  void initState() {
    super.initState();
    _appleIdCtrl =
        TextEditingController(text: widget.state.appleCreds.appleId);
    _passCtrl = TextEditingController(
        text: widget.state.appleCreds.appSpecificPassword);
  }

  @override
  void didUpdateWidget(_AppleCard old) {
    super.didUpdateWidget(old);
    if (old.state.selectedEnv != widget.state.selectedEnv ||
        old.state.projectId != widget.state.projectId) {
      _appleIdCtrl.text = widget.state.appleCreds.appleId;
      _passCtrl.text = widget.state.appleCreds.appSpecificPassword;
    }
  }

  @override
  void dispose() {
    _appleIdCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = widget.state.appleCreds.isConfigured;
    return SectionCard(
      title: 'APPLE / TESTFLIGHT',
      trailing: isConfigured
          ? const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock, size: 12, color: AppTheme.colorSuccess),
              Gap(4),
              Text('Keychain',
                  style: TextStyle(
                      color: AppTheme.colorSuccess, fontSize: 11)),
            ])
          : null,
      child: Column(
        children: [
          TextField(
            controller: _appleIdCtrl,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Apple ID (email)',
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.apple,
                  size: 16, color: Color(0xFF8B949E)),
            ),
          ),
          const Gap(10),
          TextField(
            controller: _passCtrl,
            obscureText: !_showPass,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'App-specific password',
              hintText: 'xxxx-xxxx-xxxx-xxxx',
              suffixIcon: IconButton(
                icon: Icon(
                    _showPass
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                    color: const Color(0xFF8B949E)),
                onPressed: () =>
                    setState(() => _showPass = !_showPass),
              ),
            ),
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<SettingsBloc>().add(AppleCredentialsSaved(
                      appleId: _appleIdCtrl.text.trim(),
                      appSpecificPassword: _passCtrl.text,
                    ));
              },
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save to Keychain'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Firebase Token ───────────────────────────────────────────────────────

class _FirebaseCard extends StatefulWidget {
  final SettingsState state;
  const _FirebaseCard({required this.state});

  @override
  State<_FirebaseCard> createState() => _FirebaseCardState();
}

class _FirebaseCardState extends State<_FirebaseCard> {
  late TextEditingController _tokenCtrl;
  late TextEditingController _groupsCtrl;
  bool _showToken = false;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: widget.state.firebaseToken);
    _groupsCtrl =
        TextEditingController(text: widget.state.firebaseTesterGroups);
  }

  @override
  void didUpdateWidget(_FirebaseCard old) {
    super.didUpdateWidget(old);
    if (old.state.selectedEnv != widget.state.selectedEnv ||
        old.state.projectId != widget.state.projectId) {
      _groupsCtrl.text = widget.state.firebaseTesterGroups;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _groupsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = widget.state.firebaseToken.isNotEmpty;
    return SectionCard(
      title: 'FIREBASE',
      trailing: hasToken
          ? const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock, size: 12, color: AppTheme.colorSuccess),
              Gap(4),
              Text('Keychain',
                  style: TextStyle(
                      color: AppTheme.colorSuccess, fontSize: 11)),
            ])
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tokenCtrl,
            obscureText: !_showToken,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Firebase CI token',
              hintText: 'Run: firebase login:ci',
              prefixIcon: const Icon(Icons.local_fire_department,
                  size: 16, color: Color(0xFF8B949E)),
              suffixIcon: IconButton(
                icon: Icon(
                    _showToken
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                    color: const Color(0xFF8B949E)),
                onPressed: () =>
                    setState(() => _showToken = !_showToken),
              ),
            ),
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                context
                    .read<SettingsBloc>()
                    .add(FirebaseTokenSaved(_tokenCtrl.text.trim()));
              },
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save to Keychain'),
            ),
          ),
          const Divider(height: 24),
          TextField(
            controller: _groupsCtrl,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Tester groups',
              hintText: 'internal-qa, beta-testers',
              helperText: 'Comma-separated Firebase group aliases',
              prefixIcon: Icon(Icons.group,
                  size: 16, color: Color(0xFF8B949E)),
            ),
            onChanged: (v) => context
                .read<SettingsBloc>()
                .add(EnvConfigFieldUpdated('firebase_tester_groups', v)),
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => context
                  .read<SettingsBloc>()
                  .add(const EnvConfigSaved()),
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save to YAML'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Env Config (IDs, package names) ─────────────────────────────────────

class _EnvConfigCard extends StatefulWidget {
  final SettingsState state;
  const _EnvConfigCard({required this.state});

  @override
  State<_EnvConfigCard> createState() => _EnvConfigCardState();
}

class _EnvConfigCardState extends State<_EnvConfigCard> {
  late TextEditingController _pkgCtrl;
  late TextEditingController _androidFbCtrl;
  late TextEditingController _bundleCtrl;
  late TextEditingController _iosFbCtrl;
  late TextEditingController _teamCtrl;
  late TextEditingController _provisionCtrl;
  late TextEditingController _dartDefineCtrl;

  @override
  void initState() {
    super.initState();
    _init(widget.state);
  }

  @override
  @override
  void didUpdateWidget(_EnvConfigCard old) {
    super.didUpdateWidget(old);
    if (old.state.selectedEnv != widget.state.selectedEnv ||
        old.state.projectId != widget.state.projectId) {
      _init(widget.state);
    }
  }

  void _init(SettingsState s) {
    _pkgCtrl = TextEditingController(text: s.androidPackageName);
    _androidFbCtrl = TextEditingController(text: s.androidFirebaseAppId);
    _bundleCtrl = TextEditingController(text: s.iosBundleId);
    _iosFbCtrl = TextEditingController(text: s.iosFirebaseAppId);
    _teamCtrl = TextEditingController(text: s.iosTeamId);
    _provisionCtrl = TextEditingController(text: s.iosProvisioningProfile);
    _dartDefineCtrl = TextEditingController(text: s.dartDefineFromFile);
  }

  @override
  void dispose() {
    _pkgCtrl.dispose();
    _androidFbCtrl.dispose();
    _bundleCtrl.dispose();
    _iosFbCtrl.dispose();
    _teamCtrl.dispose();
    _provisionCtrl.dispose();
    _dartDefineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDartDefineFile() async {
    const typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) return;
    final bundled = await getIt<ConfigRepository>()
        .bundleFile(widget.state.projectId, file.path);
    if (!mounted) return;
    _dartDefineCtrl.text = bundled;
    context
        .read<SettingsBloc>()
        .add(EnvConfigFieldUpdated('dart_define_from_file', bundled));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    return SectionCard(
      title: 'APP IDENTIFIERS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Android'),
          const Gap(8),
          _field('Package name', _pkgCtrl,
              'com.example.app', (v) => bloc.add(EnvConfigFieldUpdated('android_package', v))),
          const Gap(8),
          _field('Firebase App ID', _androidFbCtrl,
              '1:xxx:android:xxx', (v) => bloc.add(EnvConfigFieldUpdated('android_firebase_id', v))),
          const Gap(14),
          _sectionLabel('iOS'),
          const Gap(8),
          _field('Bundle ID', _bundleCtrl,
              'com.example.app', (v) => bloc.add(EnvConfigFieldUpdated('ios_bundle_id', v))),
          const Gap(8),
          _field('Firebase App ID', _iosFbCtrl,
              '1:xxx:ios:xxx', (v) => bloc.add(EnvConfigFieldUpdated('ios_firebase_id', v))),
          const Gap(8),
          _field('Apple Team ID', _teamCtrl,
              'ABCDE12345', (v) => bloc.add(EnvConfigFieldUpdated('ios_team_id', v))),
          const Gap(8),
          _field('Provisioning Profile', _provisionCtrl,
              'My App Distribution Profile',
              (v) => bloc.add(EnvConfigFieldUpdated('ios_provisioning_profile', v))),
          const Gap(8),
          DropdownButtonFormField<String>(
            initialValue: widget.state.iosExportMethod.isNotEmpty
                ? widget.state.iosExportMethod
                : 'app-store',
            dropdownColor: const Color(0xFF161B22),
            style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Export Method',
              prefixIcon: Icon(Icons.ios_share,
                  size: 14, color: Color(0xFF8B949E)),
            ),
            items: const [
              DropdownMenuItem(value: 'app-store', child: Text('App Store')),
              DropdownMenuItem(value: 'ad-hoc', child: Text('Ad Hoc')),
              DropdownMenuItem(value: 'development', child: Text('Development')),
              DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
            ],
            onChanged: (v) {
              if (v != null) {
                bloc.add(EnvConfigFieldUpdated('ios_export_method', v));
              }
            },
          ),
          const Gap(14),
          _sectionLabel('Dart Defines'),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dartDefineCtrl,
                  readOnly: true,
                  style: const TextStyle(
                      color: Color(0xFFE6EDF3), fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'dart-define-from-file path',
                    hintText: 'Select a .json config file',
                    prefixIcon: Icon(Icons.code,
                        size: 14, color: Color(0xFF8B949E)),
                  ),
                ),
              ),
              const Gap(8),
              OutlinedButton(
                onPressed: _pickDartDefineFile,
                child: const Text('Browse'),
              ),
            ],
          ),
          const Gap(6),
          const Text(
            'When set, --dart-define-from-file replaces individual dart-defines.',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
          ),
          const Gap(14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => bloc.add(const EnvConfigSaved()),
              icon: const Icon(Icons.save, size: 14),
              label: const Text('Save to YAML'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _field(String label, TextEditingController ctrl,
      String hint, ValueChanged<String> onChanged) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 12),
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: onChanged,
    );
  }
}

// ─── Banners ──────────────────────────────────────────────────────────────

class _SavedBanner extends StatelessWidget {
  final String message;
  const _SavedBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.colorSuccess.withValues(alpha: 0.12),
      child: Row(children: [
        const Icon(Icons.check_circle,
            size: 14, color: AppTheme.colorSuccess),
        const Gap(8),
        Text(message,
            style: const TextStyle(
                color: AppTheme.colorSuccess, fontSize: 13)),
      ]),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.colorError.withValues(alpha: 0.12),
      child: Text(error,
          style: const TextStyle(
              color: AppTheme.colorError, fontSize: 13)),
    );
  }
}
