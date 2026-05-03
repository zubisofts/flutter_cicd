import 'package:flutter/material.dart';

class EnvSelector extends StatelessWidget {
  final List<String> environments;
  final String selected;
  final ValueChanged<String> onSelected;

  const EnvSelector({
    super.key,
    required this.environments,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: environments
          .map((env) => _EnvChip(
                label: env,
                isSelected: selected == env,
                onTap: () => onSelected(env),
              ))
          .toList(),
    );
  }
}

class _EnvChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnvChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color {
    switch (label) {
      case 'dev':
        return const Color(0xFF3FB950);
      case 'staging':
        return const Color(0xFFD29922);
      case 'prod':
        return const Color(0xFFF85149);
      default:
        return const Color(0xFF58A6FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _color.withValues(alpha:0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? _color : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'prod') ...[
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: _color),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? _color : const Color(0xFF8B949E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
