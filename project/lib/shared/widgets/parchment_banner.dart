
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/soul_tokens.dart';

/// A parchment banner for the top of a category: type badge, name, song count
/// and an optional Play button.
///
/// Parchment is the same colour in both themes, so the ink on it is too (the
/// Day palette's text colour, 10:1 on parchment). Parchment is for banners
/// only, never for list rows.
class ParchmentBanner extends StatelessWidget {
  const ParchmentBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onPlay,
    this.playTooltip = 'Play',
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// When null, the Play button is hidden.
  final VoidCallback? onPlay;
  final String playTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soul = context.soul;
    final ink = AppPalette.day.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: soul.parchment,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: soul.gold.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ink.withValues(alpha: 0.10),
              ),
              child: Icon(icon, color: ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ink.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            if (onPlay != null)
              IconButton.filled(
                tooltip: playTooltip,
                iconSize: 30,
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
          ],
        ),
      ),
    );
  }
}