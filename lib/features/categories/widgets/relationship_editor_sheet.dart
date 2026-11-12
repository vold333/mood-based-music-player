
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/soul_tokens.dart';
import '../../../data/models/category.dart';
import '../../../data/models/category_relationship.dart';
import '../../../shared/widgets/soul_choice_chip.dart';
import 'category_card.dart';

/// What the user chose in the relationship editor.
class RelationshipEditorResult {
  const RelationshipEditorResult({
    this.targetCategoryId,
    this.priority = 1,
    this.remove = false,
  });

  /// The chosen target when adding. Null when editing.
  final int? targetCategoryId;
  final int priority;

  /// True when the user asked to remove the relationship being edited.
  final bool remove;
}

/// Bottom sheet for adding a relationship or changing one's priority.
///
/// When adding, the user picks a target from [targets], which must already
/// exclude the source category and categories that are already related. When
/// editing, the target is fixed and only the priority can change (or the
/// relationship can be removed).
class RelationshipEditorSheet extends StatefulWidget {
  const RelationshipEditorSheet({
    super.key,
    required this.sourceName,
    this.targets = const [],
    this.relationship,
    this.target,
  });

  final String sourceName;
  final List<Category> targets;
  final CategoryRelationship? relationship;
  final Category? target;

  static Future<RelationshipEditorResult?> showAdd(
    BuildContext context, {
    required String sourceName,
    required List<Category> targets,
  }) {
    return showModalBottomSheet<RelationshipEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RelationshipEditorSheet(
        sourceName: sourceName,
        targets: targets,
      ),
    );
  }

  static Future<RelationshipEditorResult?> showEdit(
    BuildContext context, {
    required String sourceName,
    required CategoryRelationship relationship,
    Category? target,
  }) {
    return showModalBottomSheet<RelationshipEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RelationshipEditorSheet(
        sourceName: sourceName,
        relationship: relationship,
        target: target,
      ),
    );
  }

  @override
  State<RelationshipEditorSheet> createState() =>
      _RelationshipEditorSheetState();
}

class _RelationshipEditorSheetState extends State<RelationshipEditorSheet> {
  int? _selectedId;
  late int _priority = widget.relationship?.priority ?? 1;
  String _filter = '';

  bool get _isEditing => widget.relationship != null;

  List<Category> get _filteredTargets {
    final query = _filter.trim().toLowerCase();

    if (query.isEmpty) return widget.targets;

    return widget.targets
        .where((category) => category.name.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildTargetSummary(String targetName) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(
          widget.target != null
              ? categoryIcon(widget.target!)
              : Icons.library_music_rounded,
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        targetName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: widget.target != null
          ? Text(categoryDescription(widget.target!))
          : null,
    );
  }

  List<Widget> _buildTargetPicker() {
    final accent = context.soul.accentText;
    final targets = _filteredTargets;

    return [
      // A filter only earns its space when the list is long.
      if (widget.targets.length > 8)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Filter categories',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _filter = value),
          ),
        ),
      Flexible(
        child: targets.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No matching categories.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final category = targets[index];
                  final selected = category.id == _selectedId;

                  return ListTile(
                    leading: Icon(categoryIcon(category)),
                    title: Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(categoryDescription(category)),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                    // `selected` also exposes the state to screen readers.
                    selected: selected,
                    selectedColor: accent,
                    selectedTileColor: accent.withValues(alpha: 0.10),
                    onTap: () => setState(() => _selectedId = category.id),
                  );
                },
              ),
      ),
    ];
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // The existing UI offers priorities 1 to 5. A stored value above that is
    // still shown, so editing never hides it.
    final maxChoice = math.max(5, widget.relationship?.priority ?? 5);
    final canSave = _isEditing || _selectedId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var p = 1; p <= maxChoice; p++)
                SoulChoiceChip(
                  label: '$p',
                  tooltip: p == 1 ? 'Highest priority' : null,
                  selected: _priority == p,
                  onSelected: () => setState(() => _priority = p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1 is the highest priority. Categories with the same priority '
            'are picked at random.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_isEditing)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                    onPressed: () => Navigator.pop(
                      context,
                      const RelationshipEditorResult(remove: true),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.pop(
                            context,
                            RelationshipEditorResult(
                              targetCategoryId: _selectedId,
                              priority: _priority,
                            ),
                          )
                      : null,
                  child: Text(_isEditing ? 'Save' : 'Add'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final height = MediaQuery.sizeOf(context).height;
    final targetName = widget.relationship?.toCategoryName ??
        widget.target?.name ??
        'this category';

    return Padding(
      // Keeps the sheet above the keyboard when the filter is used.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.9),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                child: Text(
                  _isEditing ? 'Change priority' : 'Add related category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  _isEditing
                      ? 'How early "$targetName" is chosen after '
                          '"${widget.sourceName}".'
                      : 'Choose the category that can follow '
                          '"${widget.sourceName}".',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_isEditing)
                _buildTargetSummary(targetName)
              else
                ..._buildTargetPicker(),
              Flexible(
                child: SingleChildScrollView(child: _buildFooter()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}