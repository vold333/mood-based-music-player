
import 'package:flutter/material.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/category_relationship.dart';
import 'category_card.dart';

/// One outgoing relationship: the target category, how many songs it has, and
/// the controls to change its priority or remove it.
class RelationshipTile extends StatelessWidget {
  const RelationshipTile({
    super.key,
    required this.relationship,
    required this.target,
    required this.songCount,
    required this.onEdit,
    required this.onRemove,
  });

  final CategoryRelationship relationship;

  /// The target category, when it is known (used for its icon).
  final Category? target;
  final int songCount;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final name =
        relationship.toCategoryName ?? target?.name ?? 'Unknown Category';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  target != null
                      ? categoryIcon(target!)
                      : Icons.library_music_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      songCount == 0
                          ? 'No songs, skipped during playback'
                          : songCountLabel(songCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Change priority',
                icon: const Icon(Icons.tune_rounded),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Remove relationship',
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}