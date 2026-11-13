import 'package:flutter/material.dart';

import '../../../core/constants/soul_assets.dart';

/// Grand Line scenic header used by the Home screen.
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
        Image.asset(
          SoulAssets.homeHeader,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scheme.primaryContainer, scheme.surface],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.02),
                scheme.surface.withValues(alpha: 0.08),
                scheme.surface.withValues(alpha: 0.52),
              ],
              stops: const [0, 0.52, 1],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E3C1).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD9A441),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    'Music Islands',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF12354F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 3),
                Text(
                  'Your music, across the Grand Line.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
