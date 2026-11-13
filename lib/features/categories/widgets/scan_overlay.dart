import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/constants/soul_assets.dart';

/// Grand Line scanning overlay. Only the count listens to scan progress.
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, required this.progress});

  final ValueListenable<int> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = AppPalette.day.onSurface;

    return ColoredBox(
      color: AppPalette.day.scrim.withValues(alpha: 0.46),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              decoration: BoxDecoration(
                color: AppPalette.day.parchment,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppPalette.day.gold,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    SoulAssets.scanningMascot,
                    width: 148,
                    height: 132,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scanning Library',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Searching for your music across the Grand Line...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ink.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      width: double.infinity,
                      child: LinearProgressIndicator(minHeight: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<int>(
                    valueListenable: progress,
                    builder: (context, count, _) {
                      return Text(
                        'Scanned: $count songs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please don’t close the app',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ink.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
