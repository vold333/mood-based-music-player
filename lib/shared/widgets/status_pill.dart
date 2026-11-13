import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../app/theme/soul_tokens.dart';

/// A small read-only label that reports a state, such as the playback mode.
///
/// It is deliberately not interactive: no ripple, no tap handler, no button
/// semantics, and a flat look (a pale sea-glass tint with a thin rim, no
/// shadow) so it cannot be mistaken for a control.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;

  /// Spoken by screen readers instead of [label], for example
  /// "Playback mode: category shuffle".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glass = context.glass;

    return Semantics(
      container: true,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: glass.skyCyan.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: glass.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: context.soul.accentText),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}