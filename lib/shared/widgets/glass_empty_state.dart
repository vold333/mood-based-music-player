import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';

/// Empty state: the illustration floats on a pool of sea light, with a title,
/// a short message and an optional action below it.
///
/// Shared by Home (no categories) and Category Songs (no songs). The artwork
/// is shown as it is, never cropped or filtered.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.asset,
    required this.title,
    required this.message,
    this.action,
  });

  final String asset;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 236,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.6,
                    colors: [
                      glass.skyCyan.withValues(alpha: 0.28),
                      glass.skyCyan.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Center(
                  child: ExcludeSemantics(
                    child: Image.asset(
                      asset,
                      width: 230,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}