import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app/theme/glass_tokens.dart';
import '../../../core/constants/soul_assets.dart';

/// Grand Line scanning overlay. Only the count listens to scan progress.
///
/// The parchment scroll carries the title; a glass panel under it holds the
/// mascot, the progress and the count. The scroll is the one place the
/// parchment appears in the new look.
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, required this.progress});

  final ValueListenable<int> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glass = context.glass;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: ColoredBox(
        color: glass.deepNavy.withValues(alpha: 0.56),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      // Keep the scanning dialog fully opaque so the Home
                      // screen cannot show through its content.
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: glass.goldHairline,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glass.deepNavy.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 148,
                          height: 132,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: 0.62,
                                colors: [
                                  glass.skyCyan.withValues(alpha: 0.30),
                                  glass.skyCyan.withValues(alpha: 0),
                                ],
                              ),
                            ),
                            child: Image.asset(
                              SoulAssets.scanningMascot,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Searching for your music across the Grand Line...',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.86),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: double.infinity,
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              color: glass.oceanBlue,
                              backgroundColor:
                                  glass.oceanBlue.withValues(alpha: 0.16),
                              semanticsLabel: 'Scanning library',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ValueListenableBuilder<int>(
                          valueListenable: progress,
                          builder: (context, count, _) {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: glass.skyCyan.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Scanned: $count songs',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Please don’t close the app',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
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