import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import 'glass_surface.dart';

/// Grand Line Glass header for a category's title, illustration and play
/// action. Replaces the parchment banner on the category songs screen.
///
/// A glass card with a thin gold hairline rim. The illustration floats on a
/// soft pool of sea light, the same motif as the Home category cards.
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({
    super.key,
    required this.artworkAsset,
    required this.title,
    required this.subtitle,
    this.onPlay,
    this.playTooltip = 'Play',
  });

  final String artworkAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onPlay;
  final String playTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glass = context.glass;

    return GlassSurface(
      radius: 28,
      rim: glass.goldHairline,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 108),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.62,
                      colors: [
                        glass.skyCyan.withValues(alpha: 0.32),
                        glass.skyCyan.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      artworkAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.library_music_rounded,
                        size: 42,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onPlay != null) ...[
                const SizedBox(width: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton.filled(
                    tooltip: playTooltip,
                    iconSize: 28,
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}