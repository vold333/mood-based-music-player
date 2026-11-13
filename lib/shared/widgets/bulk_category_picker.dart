import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import 'glass_icon_badge.dart';

/// Category destination picker followed by an explicit bulk-move confirmation.
class BulkCategoryPicker {
  static Future<int?> show(
    BuildContext context, {
    required List<Category> categories,
    required int selectedCount,
    int? excludedCategoryId,
  }) async {
    final available = categories
        .where((category) => category.id != excludedCategoryId)
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No destination categories available')),
      );
      return null;
    }

    final destinationId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move to category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: available.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = available[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GlassIconBadge(
                  size: 38,
                  icon: category.isDefault
                      ? Icons.library_music
                      : category.source == 'manual'
                          ? Icons.folder_special
                          : Icons.music_note,
                ),
                title: Text(category.name),
                subtitle: Text(
                  category.isDefault
                      ? 'System category'
                      : category.source == 'manual'
                          ? 'Custom category'
                          : 'Music genre',
                ),
                onTap: () => Navigator.pop(dialogContext, category.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (destinationId == null || !context.mounted) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm move'),
        content: Text(
          'Move $selectedCount ${selectedCount == 1 ? 'song' : 'songs'} '
          'to ${available.firstWhere((c) => c.id == destinationId).name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    return confirmed == true ? destinationId : null;
  }
}
