
import 'package:flutter/material.dart';
import '../player/playback_handler.dart';
import '../../data/models/category.dart';
import '../../data/models/song.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/services/library_scanner_service.dart';
import 'category_relationships_screen.dart';
import '../player/now_playing_screen.dart';
import '../../shared/widgets/artwork_image.dart';
import '../../shared/widgets/mini_player.dart';
import '../library/all_songs_screen.dart';

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

  
  IconData _categoryIcon(Category category) {
    if (category.isDefault) {
      return Icons.library_music_rounded;
    }

    if (category.source == 'manual') {
      return Icons.folder_special_rounded;
    }

    return Icons.music_note_rounded;
  }

  String _categoryDescription(Category category) {
    if (category.isDefault) return 'System category';
    if (category.source == 'manual') return 'Custom category';
    return 'Music genre';
  }

  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'All Songs',
            icon: const Icon(Icons.library_music_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AllSongsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Rescan Library',
            onPressed: _rescanMusicLibrary,
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Refresh Categories',
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Import Music Folder',
            onPressed: _importMusicFolder,
            icon: const Icon(Icons.folder_open_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          size: 72,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No categories found',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Import your music folder to get started.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _importMusicFolder,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Import Music'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Music Categories',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_categories.length} categories available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._categories.map((category) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(
                              _categoryIcon(category),
                              color: theme.colorScheme.onPrimaryContainer,
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
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _categoryDescription(category),
                            ),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Manage Relationships',
                                icon: const Icon(
                                  Icons.account_tree_rounded,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CategoryRelationshipsScreen(
                                        category: category,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (category.canModify)
                                PopupMenuButton<String>(
                                  tooltip: 'Category options',
                                  onSelected: (value) {
                                    if (value == 'rename') {
                                      _showCategoryDialog(
                                        category: category,
                                      );
                                    } else if (value == 'delete') {
                                      _deleteCategory(category);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Rename'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete_outline),
                                        title: Text('Delete'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.lock_outline),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
      bottomNavigationBar: const MiniPlayer(),
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
      await playbackHandlerInstance.playCategorySong(song);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NowPlayingScreen(),
        ),
      );
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
                      leading: ArtworkImage(
                        artworkPath: song.artworkPath,
                        size: 48,
                        borderRadius: 8,
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
                bottomNavigationBar: const MiniPlayer(),
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