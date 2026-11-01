
import 'package:flutter/material.dart';
import '../player/playback_handler.dart';
import '../../data/models/category.dart';
import '../../data/models/song.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/services/library_scanner_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryRepository _categoryRepository =
      CategoryRepository();

  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  final LibraryScannerService _scannerService =
    LibraryScannerService();

  Future<void> _importMusicFolder() async {
    try {
      final count = await _scannerService.pickAndScanLibrary();

      if (!mounted || count == null) return;

      await _loadCategories();

      if (!mounted) return;
      _showMessage('Import completed! $count songs scanned.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Import failed: $e');
    }
  }

  Future<void> _rescanMusicLibrary() async {
    try {
      final count = await _scannerService.rescanSavedLibrary();

      if (!mounted) return;

      if (count == null) {
        _showMessage(
          'No saved library access. Please import your music folder again.',
        );
        return;
      }

      await _loadCategories();

      if (!mounted) return;

      _showMessage('Rescan completed! $count songs scanned.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Rescan failed: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await _categoryRepository.getAllCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Failed to load categories: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  Future<void> _showCategoryDialog({
    Category? category,
  }) async {
    final isEditing = category != null;

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _CategoryNameDialog(
          initialName: category?.name ?? '',
          isEditing: isEditing,
        );
      },
    );

    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    try {
      if (isEditing) {
        await _categoryRepository.renameCategory(
          category.id!,
          name,
        );
      } else {
        await _categoryRepository.createCategory(name);
      }

      await _loadCategories();

      if (!mounted) return;

      _showMessage(
        isEditing
            ? 'Category renamed successfully'
            : 'Category created successfully',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Operation failed: $e');
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (!category.canModify) {
      _showMessage('This category cannot be deleted');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category?'),
          content: Text(
            'Delete "${category.name}"?\n\n'
            'Its songs will be moved to Uncategorized.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _categoryRepository.deleteCategory(category.id!);
      await _loadCategories();

      if (!mounted) return;
      _showMessage('Category deleted successfully');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Rescan Library',
            onPressed: _rescanMusicLibrary,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Refresh Categories',
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Import Music Folder',
            onPressed: _importMusicFolder,
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('No categories found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.library_music),
                        ),
                        title: Text(category.name),
                        subtitle: Text(
                          category.isDefault
                              ? 'System category'
                              : category.source == 'manual'
                                  ? 'Custom category'
                                  : 'Music genre',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategorySongsScreen(
                                category: category,
                              ),
                            ),
                          );
                        },
                        trailing: category.canModify
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'rename') {
                                    _showCategoryDialog(
                                      category: category,
                                    );
                                  } else if (value == 'delete') {
                                    _deleteCategory(category);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              )
                            : const Icon(Icons.lock_outline),
                      ),
                    );
                  },
                ),
    );
  }
}


class CategorySongsScreen extends StatefulWidget {
  final Category category;

  const CategorySongsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategorySongsScreen> createState() =>
      _CategorySongsScreenState();
}

class _CategorySongsScreenState
    extends State<CategorySongsScreen> {
  final SongRepository _songRepository = SongRepository();
  final CategoryRepository _categoryRepository =
      CategoryRepository();

  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _songRepository
          .getSongsByCategory(widget.category.id!);

      if (!mounted) return;

      setState(() {
        _songs = songs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load songs: $e')),
      );
    }
  }

  Future<void> _playSong(Song song) async {
    try {
      await playbackHandlerInstance.playSong(song);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback failed: $e')),
      );
    }
  }

  Future<void> _showCategorySelector(Song song) async {
    final categories =
        await _categoryRepository.getAllCategories();

    if (!mounted) return;

    final selectedCategoryId = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Move "${song.title}" to'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    Navigator.pop(
                      dialogContext,
                      category.id,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted || selectedCategoryId == null) return;

    try {
      await _songRepository.assignCategory(
        song.id!,
        selectedCategoryId,
      );

      await _loadSongs();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song category updated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update category: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            onPressed: _loadSongs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(
                  child: Text('No songs in this category'),
                )
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.music_note),
                      ),
                      title: Text(song.title),
                      subtitle: Text(
                        song.artist ?? 'Unknown Artist',
                      ),
                      onTap: () => _playSong(song),
                      trailing: IconButton(
                        tooltip: 'Change category',
                        icon: const Icon(Icons.drive_file_move),
                        onPressed: () =>
                            _showCategorySelector(song),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  final String initialName;
  final bool isEditing;

  const _CategoryNameDialog({
    required this.initialName,
    required this.isEditing,
  });

  @override
  State<_CategoryNameDialog> createState() =>
      _CategoryNameDialogState();
}

class _CategoryNameDialogState
    extends State<_CategoryNameDialog> {
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