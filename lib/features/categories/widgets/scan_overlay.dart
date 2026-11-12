
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/soul_tokens.dart';

/// Shown over the Home content while the library is being scanned.
///
/// Only the song counter listens to [progress], so a scan tick rebuilds one
/// small text widget instead of the whole screen. There is no cancel button
/// because the scanner has no cancel support.
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, required this.progress});

  final ValueListenable<int> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ColoredBox(
      color: scheme.scrim.withValues(alpha: 0.54),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      size: 44,
                      color: context.soul.accentText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scanning Library',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Searching for your music across the Grand Line...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(),
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<int>(
                      valueListenable: progress,
                      builder: (context, count, _) {
                        return Text(
                          '$count songs scanned',
                          style: theme.textTheme.bodyMedium,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please don\u2019t close the app',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}