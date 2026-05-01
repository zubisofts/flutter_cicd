import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import '../../config/config_repository.dart';
import '../../di/injection.dart';
import '../../services/credential_store.dart';
import '../../services/email_notification_service.dart';
import '../../services/slack_notification_service.dart';
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
        getIt<EmailNotificationService>(),
        getIt<SlackNotificationService>(),
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
                                  const Gap(12),
                                  _EmailNotificationCard(state: state),
                                  const Gap(12),
                                  _SlackNotificationCard(state: state),
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

// ─── Email Notifications ──────────────────────────────────────────────────

class _EmailNotificationCard extends StatefulWidget {
  final SettingsState state;
  const _EmailNotificationCard({required this.state});

  @override
  State<_EmailNotificationCard> createState() =>
      _EmailNotificationCardState();
}

class _EmailNotificationCardState extends State<_EmailNotificationCard> {
  late bool _enabled;
  late bool _useSsl;
  late bool _showPass;
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _recipientCtrl;

  @override
  void initState() {
    super.initState();
    _showPass = false;
    _initFrom(widget.state.smtpConfig);
  }

  @override
  void didUpdateWidget(_EmailNotificationCard old) {
    super.didUpdateWidget(old);
    final cfg = widget.state.smtpConfig;
    final oldCfg = old.state.smtpConfig;
    if (cfg.host != oldCfg.host ||
        cfg.recipient != oldCfg.recipient ||
        cfg.enabled != oldCfg.enabled) {
      _initFrom(cfg);
    }
  }

  void _initFrom(SmtpConfig cfg) {
    _enabled = cfg.enabled;
    _useSsl = cfg.useSsl;
    _hostCtrl = TextEditingController(text: cfg.host);
    _portCtrl = TextEditingController(text: cfg.port.toString());
    _userCtrl = TextEditingController(text: cfg.username);
    _passCtrl = TextEditingController(text: cfg.password);
    _recipientCtrl = TextEditingController(text: cfg.recipient);
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _recipientCtrl.dispose();
    super.dispose();
  }

  SmtpConfig _currentConfig() => SmtpConfig(
        enabled: _enabled,
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text.trim()) ?? 587,
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        recipient: _recipientCtrl.text.trim(),
        useSsl: _useSsl,
      );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    final isTesting = widget.state.isSendingTestEmail;
    final isConfigured = widget.state.smtpConfig.isConfigured;

    return SectionCard(
      title: 'EMAIL NOTIFICATIONS',
      trailing: isConfigured && widget.state.smtpConfig.enabled
          ? const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_active,
                  size: 12, color: AppTheme.colorSuccess),
              Gap(4),
              Text('Enabled',
                  style: TextStyle(
                      color: AppTheme.colorSuccess, fontSize: 11)),
            ])
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Send email on build completion',
                style: TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
              ),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                activeColor: AppTheme.colorSuccess,
              ),
            ],
          ),
          const Gap(10),
          // Host + Port
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _hostCtrl,
                  style: const TextStyle(
                      color: Color(0xFFE6EDF3), fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'SMTP host',
                    hintText: 'smtp.gmail.com',
                    prefixIcon: Icon(Icons.dns,
                        size: 16, color: Color(0xFF8B949E)),
                  ),
                ),
              ),
              const Gap(8),
              Expanded(
                child: TextField(
                  controller: _portCtrl,
                  style: const TextStyle(
                      color: Color(0xFFE6EDF3), fontSize: 13),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Port'),
                ),
              ),
            ],
          ),
          const Gap(6),
          // SSL toggle
          Row(
            children: [
              Switch(
                value: _useSsl,
                onChanged: (v) => setState(() {
                  _useSsl = v;
                  if (v && _portCtrl.text == '587') {
                    _portCtrl.text = '465';
                  } else if (!v && _portCtrl.text == '465') {
                    _portCtrl.text = '587';
                  }
                }),
                activeColor: AppTheme.colorRunning,
              ),
              const Gap(6),
              const Text('Use SSL (port 465)',
                  style: TextStyle(
                      color: Color(0xFF8B949E), fontSize: 12)),
              const Gap(4),
              const Text('/ STARTTLS (port 587)',
                  style: TextStyle(
                      color: Color(0xFF484F58), fontSize: 12)),
            ],
          ),
          const Gap(10),
          // Username
          TextField(
            controller: _userCtrl,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Username (email)',
              hintText: 'you@gmail.com',
              prefixIcon: Icon(Icons.person,
                  size: 16, color: Color(0xFF8B949E)),
            ),
          ),
          const Gap(10),
          // Password
          TextField(
            controller: _passCtrl,
            obscureText: !_showPass,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Password / App password',
              hintText: 'Gmail: use an App Password',
              prefixIcon: const Icon(Icons.lock,
                  size: 16, color: Color(0xFF8B949E)),
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
          const Gap(10),
          // Recipient
          TextField(
            controller: _recipientCtrl,
            style: const TextStyle(
                color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Send to (recipient)',
              hintText: 'team@example.com',
              prefixIcon: Icon(Icons.email,
                  size: 16, color: Color(0xFF8B949E)),
            ),
          ),
          const Gap(14),
          const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 13, color: Color(0xFF8B949E)),
              Gap(6),
              Expanded(
                child: Text(
                  'Credentials are stored in macOS Keychain. '
                  'For Gmail, enable 2-step verification and use an App Password.',
                  style: TextStyle(
                      color: Color(0xFF8B949E), fontSize: 11),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isTesting
                    ? null
                    : () => bloc
                        .add(EmailTestRequested(_currentConfig())),
                icon: isTesting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 14),
                label: Text(isTesting ? 'Sending…' : 'Send Test'),
              ),
              const Gap(8),
              ElevatedButton.icon(
                onPressed: () =>
                    bloc.add(EmailConfigSaved(_currentConfig())),
                icon: const Icon(Icons.save, size: 14),
                label: const Text('Save to Keychain'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Slack Notifications ──────────────────────────────────────────────────

class _SlackNotificationCard extends StatefulWidget {
  final SettingsState state;
  const _SlackNotificationCard({required this.state});

  @override
  State<_SlackNotificationCard> createState() =>
      _SlackNotificationCardState();
}

class _SlackNotificationCardState extends State<_SlackNotificationCard> {
  late bool _enabled;
  late bool _showUrl;
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _showUrl = false;
    _initFrom(widget.state.slackConfig);
  }

  @override
  void didUpdateWidget(_SlackNotificationCard old) {
    super.didUpdateWidget(old);
    final cfg = widget.state.slackConfig;
    final oldCfg = old.state.slackConfig;
    if (cfg.webhookUrl != oldCfg.webhookUrl ||
        cfg.enabled != oldCfg.enabled) {
      _initFrom(cfg);
    }
  }

  void _initFrom(SlackConfig cfg) {
    _enabled = cfg.enabled;
    _urlCtrl = TextEditingController(text: cfg.webhookUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  SlackConfig _currentConfig() => SlackConfig(
        enabled: _enabled,
        webhookUrl: _urlCtrl.text.trim(),
      );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    final isTesting = widget.state.isSendingSlackTest;
    final isConfigured = widget.state.slackConfig.isConfigured;

    return SectionCard(
      title: 'SLACK NOTIFICATIONS',
      trailing: isConfigured && widget.state.slackConfig.enabled
          ? const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_active,
                  size: 12, color: AppTheme.colorSuccess),
              Gap(4),
              Text('Enabled',
                  style: TextStyle(
                      color: AppTheme.colorSuccess, fontSize: 11)),
            ])
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Post to Slack on build completion',
                style: TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
              ),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                activeColor: AppTheme.colorSuccess,
              ),
            ],
          ),
          const Gap(10),
          TextField(
            controller: _urlCtrl,
            obscureText: !_showUrl,
            style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Incoming Webhook URL',
              hintText: 'https://hooks.slack.com/services/…',
              prefixIcon: const Icon(Icons.webhook,
                  size: 16, color: Color(0xFF8B949E)),
              suffixIcon: IconButton(
                icon: Icon(
                    _showUrl ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: const Color(0xFF8B949E)),
                onPressed: () => setState(() => _showUrl = !_showUrl),
              ),
            ),
          ),
          const Gap(10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 13, color: Color(0xFF8B949E)),
              Gap(6),
              Expanded(
                child: Text(
                  'Create a Webhook in your Slack workspace: '
                  'Apps → Incoming Webhooks → Add New Webhook. '
                  'The URL is stored in macOS Keychain.',
                  style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isTesting
                    ? null
                    : () =>
                        bloc.add(SlackTestRequested(_currentConfig())),
                icon: isTesting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 14),
                label: Text(isTesting ? 'Posting…' : 'Send Test'),
              ),
              const Gap(8),
              ElevatedButton.icon(
                onPressed: () =>
                    bloc.add(SlackConfigSaved(_currentConfig())),
                icon: const Icon(Icons.save, size: 14),
                label: const Text('Save to Keychain'),
              ),
            ],
          ),
        ],
      ),
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
