
import 'package:flutter/material.dart';

import '../../../app/theme/glass_tokens.dart';
import '../../../data/models/category.dart';
import '../../../shared/widgets/glass_icon_badge.dart';
import 'category_card.dart';

enum CategoryAction {
  relationships,
  rename,
  delete,
}

/// Bottom sheet with everything that can be done to one category.
///
/// It only reports the chosen [CategoryAction]; the Home screen performs it.
class CategoryActionsSheet extends StatelessWidget {
  const CategoryActionsSheet({super.key, required this.category});

  final Category category;

  static Future<CategoryAction?> show(
    BuildContext context,
    Category category,
  ) {
    return showModalBottomSheet<CategoryAction>(
      context: context,
      builder: (context) => CategoryActionsSheet(category: category),
    );
  }

  static const _tileShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glass = context.glass;

    return DecoratedBox(
      // A touch of sea light in the top corner; fades to the sheet colour.
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.95, -1.0),
          radius: 1.1,
          colors: [
            glass.glow.withValues(alpha: 0.16),
            glass.glow.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: GlassIconBadge(icon: categoryIcon(category)),
              title: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(categoryDescription(category)),
            ),
            // Gold hairline: decoration only.
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              color: glass.goldHairline,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  ListTile(
                    shape: _tileShape,
                    leading: const GlassIconBadge(
                      icon: Icons.account_tree_rounded,
                      size: 36,
                    ),
                    title: const Text('Manage relationships'),
                    onTap: () =>
                        Navigator.pop(context, CategoryAction.relationships),
                  ),
                  if (category.canModify) ...[
                    ListTile(
                      shape: _tileShape,
                      leading: const GlassIconBadge(
                        icon: Icons.edit_outlined,
                        size: 36,
                      ),
                      title: const Text('Rename'),
                      onTap: () =>
                          Navigator.pop(context, CategoryAction.rename),
                    ),
                    ListTile(
                      shape: _tileShape,
                      textColor: scheme.error,
                      leading: const GlassIconBadge(
                        icon: Icons.delete_outline,
                        size: 36,
                        destructive: true,
                      ),
                      title: const Text('Delete'),
                      onTap: () =>
                          Navigator.pop(context, CategoryAction.delete),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'This is a system category. It cannot be renamed '
                            'or deleted.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}