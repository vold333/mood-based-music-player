
import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import '../../data/models/category_relationship.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/category_relationship_repository.dart';

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

class _CategoryRelationshipsScreenState
    extends State<CategoryRelationshipsScreen> {
  final CategoryRepository _categoryRepository =
      CategoryRepository();

  final CategoryRelationshipRepository _relationshipRepository =
      CategoryRelationshipRepository();

  List<Category> _categories = [];
  List<CategoryRelationship> _relationships = [];

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

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _relationships = relationships;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Failed to load relationships: $e');
    }
  }

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

    final selection = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => _AddRelationshipDialog(
        categories: available,
      ),
    );

    if (!mounted || selection == null) return;

    try {
      await _relationshipRepository.addRelationship(
        fromCategoryId: widget.category.id!,
        toCategoryId: selection['categoryId']!,
        priority: selection['priority']!,
      );

      await _loadData();

      if (!mounted) return;
      _showMessage('Relationship added successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to add relationship: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.name} Relationships'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRelationship,
        icon: const Icon(Icons.add_link),
        label: const Text('Add Related Category'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _relationships.isEmpty
              ? const Center(
                  child: Text(
                    'No related categories yet.\n'
                    'Add categories to define transitions.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _relationships.length,
                  itemBuilder: (context, index) {
                    final relationship = _relationships[index];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.library_music),
                        ),
                        title: Text(
                          relationship.toCategoryName ??
                              'Unknown Category',
                        ),
                        subtitle: Text(
                          'Transition priority: ${relationship.priority}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: relationship.priority,
                                items: List.generate(
                                  5,
                                  (index) => DropdownMenuItem(
                                    value: index + 1,
                                    child: Text('${index + 1}'),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    _updatePriority(
                                      relationship,
                                      value,
                                    );
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove relationship',
                              onPressed: () =>
                                  _removeRelationship(relationship),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AddRelationshipDialog extends StatefulWidget {
  final List<Category> categories;

  const _AddRelationshipDialog({
    required this.categories,
  });

  @override
  State<_AddRelationshipDialog> createState() =>
      _AddRelationshipDialogState();
}

class _AddRelationshipDialogState
    extends State<_AddRelationshipDialog> {
  int? _selectedCategoryId;
  int _priority = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Related Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Related Category',
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem<int>(
                value: category.id!,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Transition Priority',
            ),
            items: List.generate(
              5,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text(
                  'Priority ${index + 1}'
                  '${index == 0 ? ' (Highest)' : ''}',
                ),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() => _priority = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedCategoryId == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'categoryId': _selectedCategoryId!,
                    'priority': _priority,
                  });
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
