import 'package:flutter/material.dart';

import '../../app/theme/soul_tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/category_relationship.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/category_relationship_repository.dart';
import '../../shared/widgets/glass_surface.dart';
import 'widgets/relationship_editor_sheet.dart';
import 'widgets/relationship_tile.dart';

class CategoryRelationshipsScreen extends StatefulWidget {
  final Category category;

  const CategoryRelationshipsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryRelationshipsScreen> createState() =>
      _CategoryRelationshipsScreenState();
}

/// A priority heading in the relationship list.
class _PriorityGroup {
  const _PriorityGroup({
    required this.priority,
    required this.isFirst,
    required this.count,
  });

  final int priority;
  final bool isFirst;
  final int count;
}

class _CategoryRelationshipsScreenState
    extends State<CategoryRelationshipsScreen> {
  final CategoryRepository _categoryRepository =
      CategoryRepository();

  final CategoryRelationshipRepository _relationshipRepository =
      CategoryRelationshipRepository();

  List<Category> _categories = [];
  Map<int, Category> _categoriesById = {};
  List<CategoryRelationship> _relationships = [];
  Map<int, int> _songCounts = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories =
          await _categoryRepository.getAllCategories();

      final relationships =
          await _relationshipRepository.getRelatedCategories(
        widget.category.id!,
      );

      final counts = await _categoryRepository.getCategorySongCounts();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _categoriesById = {
          for (final category in categories)
            if (category.id != null) category.id!: category,
        };
        _relationships = relationships;
        _songCounts = counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Failed to load relationships: $e');
    }
  }

  // Other categories that are not already related. The current category is
  // never offered, so it cannot be related to itself.
  List<Category> get _availableCategories {
    final relatedIds =
        _relationships.map((r) => r.toCategoryId).toSet();

    return _categories.where((category) {
      return category.id != widget.category.id &&
          !relatedIds.contains(category.id);
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addRelationship() async {
    final available = _availableCategories;

    if (available.isEmpty) {
      _showMessage('No available categories to add.');
      return;
    }

    final result = await RelationshipEditorSheet.showAdd(
      context,
      sourceName: widget.category.name,
      targets: available,
    );

    if (!mounted || result == null || result.targetCategoryId == null) {
      return;
    }

    try {
      await _relationshipRepository.addRelationship(
        fromCategoryId: widget.category.id!,
        toCategoryId: result.targetCategoryId!,
        priority: result.priority,
      );

      await _loadData();

      if (!mounted) return;
      _showMessage('Relationship added successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to add relationship: $e');
    }
  }

  Future<void> _editRelationship(
    CategoryRelationship relationship,
  ) async {
    final result = await RelationshipEditorSheet.showEdit(
      context,
      sourceName: widget.category.name,
      relationship: relationship,
      target: _categoriesById[relationship.toCategoryId],
    );

    if (!mounted || result == null) return;

    if (result.remove) {
      await _removeRelationship(relationship);
      return;
    }

    if (result.priority != relationship.priority) {
      await _updatePriority(relationship, result.priority);
    }
  }

  Future<void> _updatePriority(
    CategoryRelationship relationship,
    int priority,
  ) async {
    try {
      await _relationshipRepository.updatePriority(
        relationshipId: relationship.id!,
        priority: priority,
      );

      await _loadData();

      if (!mounted) return;
      _showMessage('Priority updated.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to update priority: $e');
    }
  }

  Future<void> _removeRelationship(
    CategoryRelationship relationship,
  ) async {
    try {
      await _relationshipRepository.removeRelationship(
        relationship.id!,
      );

      await _loadData();

      if (!mounted) return;
      _showMessage('Relationship removed.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to remove relationship: $e');
    }
  }

  // Turns the relationships (already sorted by priority) into priority
  // headings followed by their relationships.
  List<Object> _buildRows() {
    final rows = <Object>[];

    int? currentPriority;
    var groupIndex = -1;

    for (final relationship in _relationships) {
      if (relationship.priority != currentPriority) {
        currentPriority = relationship.priority;
        groupIndex++;

        rows.add(
          _PriorityGroup(
            priority: relationship.priority,
            isFirst: groupIndex == 0,
            count: _relationships
                .where((r) => r.priority == relationship.priority)
                .length,
          ),
        );
      }

      rows.add(relationship);
    }

    return rows;
  }

  Widget _buildExplainer() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.alt_route_rounded,
              size: 28,
              color: context.soul.accentText,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where the music goes next',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When every song in "${widget.category.name}" has '
                    'played, playback moves on to one of its related '
                    'categories. It picks the highest priority that has '
                    'songs (1 is the highest). If several share that '
                    'priority, one is chosen at random. If none has songs, '
                    'playback stops.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildEmptyState({required bool hasTargets}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            child: Icon(
              Icons.add_link_rounded,
              size: 44,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No related categories yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hasTargets
                ? 'Add a category to continue the music after '
                    '"${widget.category.name}" finishes. Without one, '
                    'playback stops at the end of this category.'
                : 'There are no other categories to relate to yet. '
                    'Create another category from Home first.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllRelatedNote() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        'Every other category is already related.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRow(List<Object> rows, int index) {
    final row = rows[index];

    if (row is _PriorityGroup) {
      return Padding(
        padding: EdgeInsets.only(top: index == 0 ? 0 : 16, bottom: 8),
        child: _PriorityHeader(group: row),
      );
    }

    final relationship = row as CategoryRelationship;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RelationshipTile(
        relationship: relationship,
        target: _categoriesById[relationship.toCategoryId],
        songCount: _songCounts[relationship.toCategoryId] ?? 0,
        onEdit: () => _editRelationship(relationship),
        onRemove: () => _removeRelationship(relationship),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableCategories;
    final rows = _buildRows();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Relationships'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: !_loading && available.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _addRelationship,
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Add related category'),
            )
          : null,
      body: Stack(
        children: [
          const Positioned.fill(child: GrandLineBackdrop()),
          Positioned.fill(
            child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildExplainer(),
                  ),
                ),
                if (rows.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(hasTargets: available.isNotEmpty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRow(rows, index),
                        childCount: rows.length,
                                  ),
                                ),
                  ),
                if (rows.isNotEmpty && available.isEmpty)
                  SliverToBoxAdapter(child: _buildAllRelatedNote()),
                // Room for the Add button.
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
                          ],
                        ),
          ),
        ],
      ),
    );
  }
}

/// Heading for a group of relationships that share a priority.
class _PriorityHeader extends StatelessWidget {
  const _PriorityHeader({required this.group});

  final _PriorityGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final caption = [
      group.isFirst ? 'Tried first' : 'Tried if nothing above has songs',
      if (group.count > 1) 'random pick among ${group.count}',
    ].join(' \u00b7 ');

    return Row(
        children: [
        // The number is also in the text beside it, so it is hidden from
        // screen readers here.
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: group.isFirst ? scheme.primary : scheme.primaryContainer,
            ),
            child: FittedBox(
                child: Text(
                '${group.priority}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: group.isFirst
                      ? scheme.onPrimary
                      : scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Priority ${group.priority}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
        ),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}