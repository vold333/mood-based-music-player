import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

/// Round icon badge used in sheets and pickers: a pool of sea light under a
/// small icon, with a thin bright rim. Decoration only, so it adds nothing to
/// the semantics of the row it sits in.
///
/// [destructive] swaps the sea light for a soft error tint (Delete).
class GlassIconBadge extends StatelessWidget {
  const GlassIconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.destructive = false,
  });

  final IconData icon;
  final double size;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = context.glass;

    final Color iconColor =
        destructive ? scheme.error : scheme.onSecondaryContainer;

    final BoxDecoration decoration = destructive
        ? BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.error.withValues(alpha: 0.12),
            border: Border.all(color: glass.border),
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 1.0,
              colors: [
                glass.skyCyan.withValues(alpha: 0.42),
                scheme.secondaryContainer,
              ],
            ),
            border: Border.all(color: glass.border),
          );

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: decoration,
          child: Center(
            child: Icon(icon, size: size * 0.5, color: iconColor),
          ),
        ),
      ),
    );
  }
}