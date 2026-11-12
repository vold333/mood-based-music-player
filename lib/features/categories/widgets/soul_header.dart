
import 'package:flutter/material.dart';

import '../../../shared/widgets/wave_strip.dart';

/// Expanded background of the Home app bar: a theme-coloured sky fading into
/// the page, a static wave band, and the "Music Islands" title block.
///
/// Drawn entirely from the active theme, so Night and Day share this widget.
/// The text sits above the waves and never over them.
class SoulHeader extends StatelessWidget {
  const SoulHeader({
    super.key,
    required this.subtitle,
    this.showTagline = true,
  });

  final String subtitle;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.primaryContainer, scheme.surface],
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: WaveStrip(height: 56),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Music Islands',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 4),
                Text(
                  'Your music, across the Grand Line.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}