import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

/// A single-choice chip in the Soul King style, used for sort options and
/// priority choices.
///
/// The selected state is shown by a check mark as well as by colour, so it
/// never depends on colour alone.
class SoulChoiceChip extends StatelessWidget {
  const SoulChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  /// Optional longer description, for example "Longest first".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final chip = ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: true,
      // Glass pill: a light translucent fill that turns Soul Purple tinted
      // when selected. The tick still marks the choice, not colour alone.
      backgroundColor: context.glass.fillStrong,
      elevation: 0,
      pressElevation: 0,
      shape: const StadiumBorder(),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
      ),
      side: BorderSide(
        color: selected ? scheme.primaryContainer : scheme.outline,
      ),
    );

    if (tooltip == null) return chip;

    return Tooltip(message: tooltip!, child: chip);
  }
}