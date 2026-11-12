
import 'package:flutter/material.dart';

/// Dialog for creating or renaming a category. Pops with the trimmed name.
class CategoryNameDialog extends StatefulWidget {
  final String initialName;
  final bool isEditing;

  const CategoryNameDialog({
    super.key,
    required this.initialName,
    required this.isEditing,
  });

  @override
  State<CategoryNameDialog> createState() =>
      _CategoryNameDialogState();
}

class _CategoryNameDialogState
    extends State<CategoryNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Rename Category' : 'Create Category',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: const InputDecoration(
          labelText: 'Category name',
          hintText: 'Enter category name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _controller.text.trim(),
          ),
          child: Text(widget.isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}