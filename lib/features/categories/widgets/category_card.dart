
import 'package:flutter/material.dart';

import '../../../data/models/category.dart';
import '../../../core/constants/soul_assets.dart';

/// Icon for a category by type: system, custom or music genre.
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

/// One category in the Home grid. Tapping opens its songs; the options button
/// opens the actions sheet (relationships, rename, delete).
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

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 62,
                    height: 54,
                    child: Image.asset(
                      SoulAssets.artworkForCategory(category),
                      fit: BoxFit.contain,
                      semanticLabel: '${category.name} illustration',
                      errorBuilder: (_, __, ___) => Icon(
                      categoryIcon(category),
                        color: scheme.primary,
                        size: 34,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Category options',
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: onMore,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            songCountLabel(songCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (!category.canModify) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                            semanticLabel:
                                'System category, cannot be changed',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}