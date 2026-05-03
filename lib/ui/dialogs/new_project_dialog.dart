import 'package:flutter/material.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  static Future<({String id, String name, String repo})?> show(
      BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const NewProjectDialog(),
    );
  }

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _repoCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _repoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      title: const Text(
        'Add New Project',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                controller: _idCtrl,
                label: 'Project ID',
                hint: 'my_app (snake_case, no spaces)',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[a-z][a-z0-9_]+$').hasMatch(v)) {
                    return 'Use lowercase letters, numbers, underscores';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _field(
                controller: _nameCtrl,
                label: 'Project Name',
                hint: 'My Application',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _repoCtrl,
                label: 'Repository URL',
                hint: 'git@github.com:org/repo.git',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF8B949E))),
        ),
        ElevatedButton(
          onPressed: () {
            if (_form.currentState?.validate() == true) {
              Navigator.of(context).pop((
                id: _idCtrl.text.trim(),
                name: _nameCtrl.text.trim(),
                repo: _repoCtrl.text.trim(),
              ));
            }
          },
          child: const Text('Create Project'),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
