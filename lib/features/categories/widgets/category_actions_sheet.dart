
import 'package:flutter/material.dart';

import '../../../data/models/category.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                categoryIcon(category),
                color: scheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(categoryDescription(category)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.account_tree_rounded),
            title: const Text('Manage relationships'),
            onTap: () => Navigator.pop(context, CategoryAction.relationships),
          ),
          if (category.canModify) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, CategoryAction.rename),
            ),
            ListTile(
              iconColor: scheme.error,
              textColor: scheme.error,
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, CategoryAction.delete),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Text(
                'This is a system category. It cannot be renamed or deleted.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}