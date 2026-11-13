import 'package:flutter/material.dart';

import '../../app/theme/soul_tokens.dart';
import '../../core/constants/soul_assets.dart';
import '../../data/models/song.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/mini_player.dart';
import '../../shared/widgets/song_tile.dart';
import '../../shared/widgets/soul_choice_chip.dart';
import '../../shared/widgets/bulk_category_picker.dart';
import '../player/playback_handler.dart';
import '../player/now_playing_screen.dart';

enum SongSortOption {
  title,
  artist,
  duration,
}

class AllSongsScreen extends StatefulWidget {
  /// Opens with the search field focused (used by the Home search shortcut).
  final bool autofocusSearch;

  const AllSongsScreen({super.key, this.autofocusSearch = false});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

/// A song with its lowercase sort and search keys, computed once per load so
/// typing and sorting stay fast on large libraries.
class _SongEntry {
  _SongEntry(this.song)
      : titleKey = song.title.toLowerCase(),
        artistKey = (song.artist ?? 'Unknown Artist').toLowerCase(),
        searchKey = [
          song.title,
          song.artist ?? '',
          song.album ?? '',
          song.categoryName ?? '',
        ].join('\n').toLowerCase();

  final Song song;
  final String titleKey;
  final String artistKey;
  final String searchKey;
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  final SongRepository _songRepository = SongRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final Set<int> _selectedSongIds = {};
  final TextEditingController _searchController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Every song, in the selected sort order.
  List<_SongEntry> _entries = [];

  // The entries that match the search, in the same order.
  List<_SongEntry> _visible = [];

  bool _loading = true;
  SongSortOption _sortOption = SongSortOption.title;

  String _appliedQuery = '';
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    final query = _searchController.text.trim().toLowerCase();
    final hasText = _searchController.text.isNotEmpty;

    // Cursor moves also notify the controller; only react to real changes.
    if (query == _appliedQuery && hasText == _hasText) return;

    setState(() {
      _appliedQuery = query;
      _hasText = hasText;
      _applyFilter();
    });

    _scrollToTop();
  }

  Future<void> _loadSongs() async {
    if (_loading == false) {
      setState(() => _loading = true);
    }

    try {
      final songs = await _songRepository.getAllSongsWithCategory();

      if (!mounted) return;

      setState(() {
        _entries = songs.map(_SongEntry.new).toList();
        final availableIds = songs.map((song) => song.id).whereType<int>().toSet();
        _selectedSongIds.removeWhere((id) => !availableIds.contains(id));
        _sortEntries();
        _applyFilter();
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

  // Sorts every song. Ties fall back to the title, then the song ID, so the
  // order is always the same for the same library.
  void _sortEntries() {
    int compare(_SongEntry a, _SongEntry b) {
      final primary = switch (_sortOption) {
        SongSortOption.title => a.titleKey.compareTo(b.titleKey),
        SongSortOption.artist => a.artistKey.compareTo(b.artistKey),
        SongSortOption.duration =>
          b.song.duration.compareTo(a.song.duration),
      };

      if (primary != 0) return primary;

      final byTitle = a.titleKey.compareTo(b.titleKey);

      if (byTitle != 0) return byTitle;

      return (a.song.id ?? 0).compareTo(b.song.id ?? 0);
    }

    _entries.sort(compare);
  }

  // Keeps the songs that match the search. The order is preserved.
  void _applyFilter() {
    if (_appliedQuery.isEmpty) {
      _visible = _entries;
      return;
    }

    _visible = _entries
        .where((entry) => entry.searchKey.contains(_appliedQuery))
        .toList();
  }

  void _changeSort(SongSortOption option) {
    if (option == _sortOption) return;

    setState(() {
      _sortOption = option;
      _sortEntries();
      _applyFilter();
    });

    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  bool get _selectionMode => _selectedSongIds.isNotEmpty;

  void _toggleSelection(Song song) {
    final id = song.id;
    if (id == null) return;
    setState(() {
      if (!_selectedSongIds.add(id)) {
        _selectedSongIds.remove(id);
      }
    });
  }

  void _selectVisible() {
    setState(() {
      for (final entry in _visible) {
        final id = entry.song.id;
        if (id != null) _selectedSongIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(_selectedSongIds.clear);
  }

  Future<void> _moveSelectedSongs() async {
    if (_selectedSongIds.isEmpty) return;
    try {
      final categories = await _categoryRepository.getAllCategories();
      if (!mounted) return;
      final ids = List<int>.from(_selectedSongIds);
      final destinationId = await BulkCategoryPicker.show(
        context,
        categories: categories,
        selectedCount: ids.length,
      );
      if (!mounted || destinationId == null) return;

      final result = await _songRepository.assignCategoryBulk(ids, destinationId);
      if (!mounted) return;
      setState(_selectedSongIds.clear);
      await _loadSongs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Moved ${result.moved}; unchanged ${result.unchanged}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to move songs: $e')),
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

  String _sortLabel(SongSortOption option) {
    switch (option) {
      case SongSortOption.title:
        return 'Title';
      case SongSortOption.artist:
        return 'Artist';
      case SongSortOption.duration:
        return 'Duration';
    }
  }

  String get _sortDescription {
    switch (_sortOption) {
      case SongSortOption.title:
        return 'Sorted A-Z by title';
      case SongSortOption.artist:
        return 'Sorted A-Z by artist';
      case SongSortOption.duration:
        return 'Longest first';
    }
  }

  String _countLabel(int count) {
    return count == 1 ? '1 song' : '$count songs';
  }

  String get _summary {
    final total = _entries.length;

    final count = _appliedQuery.isEmpty
        ? _countLabel(total)
        : '${_visible.length} of ${_countLabel(total)}';

    return '$count \u00b7 $_sortDescription';
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // The glass pill supplies the fill and rim; the field itself is clear and
    // only draws a clear accent outline while focused.
    return GlassSurface(
      radius: 20,
      child: TextField(
        controller: _searchController,
        autofocus: widget.autofocusSearch,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search songs, artists, albums...',
          hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _hasText
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _searchController.clear,
                )
              : null,
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: context.soul.accentText,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final option in SongSortOption.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SoulChoiceChip(
                label: _sortLabel(option),
                tooltip: option == SongSortOption.duration
                    ? 'Longest first'
                    : null,
                selected: option == _sortOption,
                onSelected: () => _changeSort(option),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? illustrationAsset,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustrationAsset != null)
              Image.asset(
                illustrationAsset,
                width: 220,
                height: 210,
                fit: BoxFit.contain,
              )
            else
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
              child: Icon(
              icon,
                size: 44,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSongList() {
    final songs = _visible;

    // One glass panel holds the whole list. Rows are built lazily inside it,
    // so a large library never builds hundreds of shadowed cards.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: GlassSurface(
        radius: 28,
        child: Material(
          type: MaterialType.transparency,
          child: ListView.separated(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 84,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final song = songs[index].song;

              final selected =
                  song.id != null && _selectedSongIds.contains(song.id);
              return SongTile(
                song: song,
                selectionMode: _selectionMode,
                selected: selected,
                onLongPress: () {
                  if (!_selectionMode) _toggleSelection(song);
                },
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelection(song);
                  } else {
                    _playSong(song);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Exit selection',
                onPressed: _clearSelection,
                icon: const Icon(Icons.close_rounded),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _selectionMode ? '${_selectedSongIds.length} selected' : 'All Songs',
        ),
        actions: _selectionMode
            ? [
                TextButton(
                  onPressed: _selectVisible,
                  child: Text(_appliedQuery.isEmpty ? 'Select all' : 'Select visible'),
                ),
                IconButton(
                  tooltip: 'Clear selection',
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.deselect_rounded),
                ),
                IconButton(
                  tooltip: 'Move to category',
                  onPressed: _moveSelectedSongs,
                  icon: const Icon(Icons.drive_file_move_outlined),
                ),
              ]
            : [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadSongs,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: GrandLineBackdrop()),
          Positioned.fill(
            child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState(
                  icon: Icons.library_music_outlined,
                  title: 'Your library is empty',
                  subtitle:
                      'Import a music folder to discover your songs.',
                  illustrationAsset: SoulAssets.emptyLibrary,
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _buildSearchField(),
                    ),
                    _buildSortChips(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _visible.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No matching songs',
                              subtitle:
                                  'Try another song, artist or album name.',
                              illustrationAsset: SoulAssets.noSearchResults,
                              action: FilledButton.tonal(
                                onPressed: _searchController.clear,
                                child: const Text('Clear search'),
                                      ),
                            )
                          : _buildSongList(),
                    ),
                  ],
                ),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}