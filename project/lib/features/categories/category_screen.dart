
import 'package:flutter/material.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/services/library_scanner_service.dart';
import '../../shared/widgets/mini_player.dart';
import '../../shared/widgets/theme_selector_sheet.dart';
import '../library/all_songs_screen.dart';
import 'category_name_dialog.dart';
import 'category_relationships_screen.dart';
import 'category_songs_screen.dart';
import 'widgets/category_actions_sheet.dart';
import 'widgets/category_card.dart';
import 'widgets/scan_overlay.dart';
import 'widgets/soul_header.dart';

enum _HomeAction {
  theme,
  importFolder,
  rescan,
  refresh,
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryRepository _categoryRepository =
      CategoryRepository();

  final LibraryScannerService _scannerService =
      LibraryScannerService();

  // Updated by the scanner callback. Only the scan overlay listens to it, so a
  // scan tick no longer rebuilds the whole screen.
  final ValueNotifier<int> _scanProgress = ValueNotifier<int>(0);

  List<Category> _categories = [];
  Map<int, int> _songCounts = {};
  bool _loading = true;

  bool _isScanning = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _scanProgress.dispose();
    super.dispose();
  }

  void _reportScanProgress(int count) {
    if (mounted) {
      _scanProgress.value = count;
    }
  }

  Future<void> _importMusicFolder() async {
    if (_isScanning) return;

    _scanProgress.value = 0;
    setState(() => _isScanning = true);

    try {
      final count = await _scannerService.pickAndScanLibrary(
        onProgress: _reportScanProgress,
      );

      if (!mounted || count == null) return;

      await _loadCategories();

      if (!mounted) return;
      _showMessage('Import completed! $count songs scanned.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _rescanMusicLibrary() async {
    if (_isScanning) return;

    _scanProgress.value = 0;
    setState(() => _isScanning = true);

    try {
      final count = await _scannerService.rescanSavedLibrary(
        onProgress: _reportScanProgress,
      );

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
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _loadCategories({bool showProgress = false}) async {
    if (showProgress && mounted) {
      setState(() => _refreshing = true);
    }

    try {
      final categories = await _categoryRepository.getAllCategories();
      final counts = await _categoryRepository.getCategorySongCounts();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _songCounts = counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Failed to load categories: $e');
    } finally {
      if (mounted && showProgress) {
        setState(() => _refreshing = false);
      }
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
        return CategoryNameDialog(
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

  Future<void> _openSongs(Category category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySongsScreen(category: category),
      ),
    );

    // Songs can be moved to another category on that screen, so refresh the
    // categories and their song counts when it is closed.
    if (!mounted) return;
    await _loadCategories();
  }

  void _openRelationships(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryRelationshipsScreen(category: category),
      ),
    );
  }
  
  void _openAllSongs({bool focusSearch = false}) {
              Navigator.push(
                context,
                MaterialPageRoute(
        builder: (_) => AllSongsScreen(autofocusSearch: focusSearch),
                ),
              );
  }

  Future<void> _showCategoryActions(Category category) async {
    final action = await CategoryActionsSheet.show(context, category);

    if (!mounted || action == null) return;

    switch (action) {
      case CategoryAction.relationships:
        _openRelationships(category);
      case CategoryAction.rename:
        await _showCategoryDialog(category: category);
      case CategoryAction.delete:
        await _deleteCategory(category);
    }
  }

  void _onMenuSelected(_HomeAction action) {
    switch (action) {
      case _HomeAction.theme:
        ThemeSelectorSheet.show(context);
      case _HomeAction.importFolder:
        _importMusicFolder();
      case _HomeAction.rescan:
        _rescanMusicLibrary();
      case _HomeAction.refresh:
        _loadCategories(showProgress: true);
    }
  }

  String get _headerSubtitle {
    if (_loading) return 'Loading your library...';

    final total = _songCounts.values.fold<int>(0, (sum, n) => sum + n);
    final categories = _categories.length == 1
        ? '1 category'
        : '${_categories.length} categories';

    return '$categories \u00b7 ${songCountLabel(total)}';
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
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
    );
  }

  Widget _buildCategoryGrid(double textScale) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;

          var columns = width >= 760 ? 4 : (width >= 520 ? 3 : 2);

          // At very large text sizes two narrow columns would clip names.
          if (textScale > 1.8 && columns == 2) columns = 1;

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // Card height follows the text size, so larger text never
              // overflows the card.
              mainAxisExtent: 76 + 64 * textScale,
            ),
            // Built lazily, so a large library only builds what is on screen.
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = _categories[index];

                return CategoryCard(
                  category: category,
                  songCount: _songCounts[category.id] ?? 0,
                  onTap: () => _openSongs(category),
                  onMore: () => _showCategoryActions(category),
                );
              },
              childCount: _categories.length,
            ),
      );
        },
      ),
    );
  }

  Widget _buildAllSongsRow() {
    final scheme = Theme.of(context).colorScheme;
    final total = _songCounts.values.fold<int>(0, (sum, n) => sum + n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
                    leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
                      child: Icon(
              Icons.library_music_rounded,
              color: scheme.onPrimaryContainer,
            ),
          ),
          title: const Text('All Songs'),
          subtitle: Text(songCountLabel(total)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _openAllSongs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rawScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final textScale = rawScale < 1 ? 1.0 : rawScale;
    final headerExtra = (textScale - 1).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add category',
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add_rounded),
      ),
      body: Stack(
                  children: [
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 196 + 64 * headerExtra,
                  title: Text(
                    'Soul King',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Search songs',
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => _openAllSongs(focusSearch: true),
                    ),
                    PopupMenuButton<_HomeAction>(
                      tooltip: 'More options',
                      onSelected: _onMenuSelected,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _HomeAction.theme,
                          child: ListTile(
                            leading: Icon(Icons.brightness_6_rounded),
                            title: Text('Theme'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _HomeAction.importFolder,
                          enabled: !_isScanning,
                          child: ListTile(
                            enabled: !_isScanning,
                            leading: const Icon(Icons.folder_open_rounded),
                            title: const Text('Import music folder'),
                            contentPadding: EdgeInsets.zero,
                            ),
                        ),
                        PopupMenuItem(
                          value: _HomeAction.rescan,
                          enabled: !_isScanning,
                          child: ListTile(
                            enabled: !_isScanning,
                            leading: const Icon(Icons.sync_rounded),
                            title: const Text('Rescan library'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _HomeAction.refresh,
                          enabled: !_isScanning && !_refreshing,
                          child: ListTile(
                            enabled: !_isScanning && !_refreshing,
                            leading: const Icon(Icons.refresh_rounded),
                            title: const Text('Refresh categories'),
                            contentPadding: EdgeInsets.zero,
                          ),
                      ),
                      ],
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: _refreshing
                        ? const LinearProgressIndicator(minHeight: 2)
                        : const SizedBox(height: 2),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: SoulHeader(
                      subtitle: _headerSubtitle,
                      showTagline: textScale <= 1.3,
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_categories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(theme),
                  )
                else ...[
                  _buildCategoryGrid(textScale),
                  SliverToBoxAdapter(child: _buildAllSongsRow()),
                ],
              ],
            ),
          ),

          // Covers the content below the toolbar, so the toolbar actions (for
          // example Theme) stay usable while a scan is running.
          if (_isScanning)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: MediaQuery.paddingOf(context).top + kToolbarHeight,
              child: ScanOverlay(progress: _scanProgress),
          ),
      ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}