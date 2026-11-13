import 'package:flutter/material.dart';

import '../../../app/theme/glass_tokens.dart';
import '../../../core/constants/soul_assets.dart';
import '../../../data/models/category.dart';
import '../../../shared/widgets/glass_surface.dart';

/// Icon fallback for a category if its illustration cannot be loaded.
IconData categoryIcon(Category category) {
  if (category.isDefault) return Icons.anchor_rounded;
  if (category.source == 'manual') return Icons.flag_rounded;
  return Icons.beach_access_rounded;
}

String categoryDescription(Category category) {
  if (category.isDefault) return 'System category';
  if (category.source == 'manual') return 'Custom category';
  return 'Music genre';
}

String songCountLabel(int count) => count == 1 ? '1 song' : '$count songs';

/// Compact Grand Line Glass category card used by the Home grid.
///
/// A glass tile with the category illustration floating on a soft pool of sea
/// light. No blur here: the grid can hold many cards, so the tile uses the
/// strong translucent fill over the page backdrop instead.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.songCount,
    required this.onTap,
    required this.onMore,
  });

  final Category category;
  final int songCount;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glass = context.glass;

    return GlassSurface(
      radius: 24,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pool of sea light behind the illustration.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, 0.15),
                              radius: 0.62,
                              colors: [
                                glass.skyCyan.withValues(alpha: 0.30),
                                glass.skyCyan.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 3, 18, 0),
                        child: Image.asset(
                          SoulAssets.artworkForCategory(category),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          semanticLabel: '${category.name} illustration',
                          errorBuilder: (_, __, ___) => Icon(
                            categoryIcon(category),
                            color: scheme.primary,
                            size: 42,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -5,
                        right: -8,
                        child: IconButton(
                          tooltip: 'Category options',
                          visualDensity: VisualDensity.compact,
                          iconSize: 21,
                          color: scheme.onSurfaceVariant,
                          icon: const Icon(Icons.more_vert_rounded),
                          onPressed: onMore,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer
                              .withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          child: Text(
                            songCountLabel(songCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!category.canModify) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                        semanticLabel: 'System category, cannot be changed',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
