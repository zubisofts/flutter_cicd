import 'package:flutter/material.dart';

class _CheckboxGroup extends StatelessWidget {
  final List<_CheckItem> items;

  const _CheckboxGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _CheckChip(item: item)).toList(),
    );
  }
}

class _CheckItem {
  final String value;
  final String label;
  final IconData icon;
  final bool checked;
  final VoidCallback onToggle;

  const _CheckItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.checked,
    required this.onToggle,
  });
}

class PlatformSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const PlatformSelector({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckboxGroup(items: [
      _CheckItem(
        value: 'android',
        label: 'Android',
        icon: Icons.android,
        checked: selected.contains('android'),
        onToggle: () => onToggle('android'),
      ),
      _CheckItem(
        value: 'ios',
        label: 'iOS',
        icon: Icons.apple,
        checked: selected.contains('ios'),
        onToggle: () => onToggle('ios'),
      ),
    ]);
  }
}

class TargetSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const TargetSelector({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckboxGroup(items: [
      _CheckItem(
        value: 'firebase_android',
        label: 'Firebase (Android)',
        icon: Icons.local_fire_department,
        checked: selected.contains('firebase_android'),
        onToggle: () => onToggle('firebase_android'),
      ),
      _CheckItem(
        value: 'firebase_ios',
        label: 'Firebase (iOS)',
        icon: Icons.local_fire_department,
        checked: selected.contains('firebase_ios'),
        onToggle: () => onToggle('firebase_ios'),
      ),
      _CheckItem(
        value: 'testflight',
        label: 'TestFlight',
        icon: Icons.flight_takeoff,
        checked: selected.contains('testflight'),
        onToggle: () => onToggle('testflight'),
      ),
      _CheckItem(
        value: 'playstore',
        label: 'Play Store',
        icon: Icons.store,
        checked: selected.contains('playstore'),
        onToggle: () => onToggle('playstore'),
      ),
    ]);
  }
}

class _CheckChip extends StatelessWidget {
  final _CheckItem item;
  const _CheckChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onToggle,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: item.checked
              ? const Color(0xFF58A6FF).withValues(alpha:0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: item.checked
                ? const Color(0xFF58A6FF)
                : const Color(0xFF30363D),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.checked
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              size: 16,
              color: item.checked
                  ? const Color(0xFF58A6FF)
                  : const Color(0xFF8B949E),
            ),
            const SizedBox(width: 8),
            Icon(
              item.icon,
              size: 14,
              color: item.checked
                  ? const Color(0xFF58A6FF)
                  : const Color(0xFF8B949E),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                color: item.checked
                    ? const Color(0xFFE6EDF3)
                    : const Color(0xFF8B949E),
                fontSize: 13,
                fontWeight:
                    item.checked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
