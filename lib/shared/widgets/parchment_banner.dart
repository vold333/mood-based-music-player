import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../core/constants/soul_assets.dart';

/// Grand Line parchment banner for a category's title, artwork and play action.
class ParchmentBanner extends StatelessWidget {
  const ParchmentBanner({
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
    final ink = AppPalette.day.onSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        decoration: BoxDecoration(
          color: AppPalette.day.parchment,
          border: Border.all(
            color: AppPalette.day.gold.withValues(alpha: 0.85),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                SoulAssets.categoryBanner,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) =>
                    const SizedBox.expand(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 14, 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 68,
                    child: Image.asset(
                      artworkAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.library_music_rounded,
                        size: 42,
                        color: ink,
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
                            color: ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ink.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onPlay != null) ...[
                    const SizedBox(width: 6),
                    IconButton.filled(
                      tooltip: playTooltip,
                      iconSize: 28,
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
