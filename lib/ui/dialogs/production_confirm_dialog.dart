import 'package:flutter/material.dart';

class ProductionConfirmDialog extends StatefulWidget {
  final String requiredPhrase;
  final VoidCallback onConfirmed;

  const ProductionConfirmDialog({
    super.key,
    required this.requiredPhrase,
    required this.onConfirmed,
  });

  static Future<bool?> show(
      BuildContext context, String phrase, VoidCallback onConfirmed) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductionConfirmDialog(
        requiredPhrase: phrase,
        onConfirmed: onConfirmed,
      ),
    );
  }

  @override
  State<ProductionConfirmDialog> createState() =>
      _ProductionConfirmDialogState();
}

class _ProductionConfirmDialogState
    extends State<ProductionConfirmDialog> {
  String _input = '';

  bool get _valid => _input.trim() == widget.requiredPhrase;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1016),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFF85149), width: 1),
      ),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF85149), size: 22),
          SizedBox(width: 8),
          Text(
            'Production Deployment',
            style: TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to deploy to PRODUCTION. This will affect '
              'real users immediately.\n\n'
              'Type the phrase below to confirm:',
              style: TextStyle(color: Color(0xFFE6EDF3), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.fromBorderSide(
                    BorderSide(color: Theme.of(context).colorScheme.outline)),
              ),
              child: SelectableText(
                '"${widget.requiredPhrase}"',
                style: const TextStyle(
                  color: Color(0xFFF85149),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _input = v),
              style: const TextStyle(
                  color: Color(0xFFE6EDF3), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type the phrase here...',
                suffixIcon: _valid
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF3FB950), size: 18)
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF8B949E))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _valid ? const Color(0xFFF85149) : const Color(0xFF30363D),
            foregroundColor: Colors.white,
          ),
          onPressed: _valid
              ? () {
                  Navigator.of(context).pop(true);
                  widget.onConfirmed();
                }
              : null,
          child: const Text('CONFIRM DEPLOY'),
        ),
      ],
    );
  }
}
