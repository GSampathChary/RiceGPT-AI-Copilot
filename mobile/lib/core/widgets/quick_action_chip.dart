import 'package:flutter/material.dart';

class QuickActionChip extends StatelessWidget {
  const QuickActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      shape: StadiumBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}

