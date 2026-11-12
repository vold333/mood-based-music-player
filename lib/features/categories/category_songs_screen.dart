
import 'dart:math';

import 'package:flutter/material.dart';
import '../player/playback_handler.dart';
import '../../data/models/category.dart';
import '../../data/models/song.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../shared/widgets/bulk_category_picker.dart';
import '../player/now_playing_screen.dart';
import '../../shared/widgets/artwork_image.dart';
import '../../shared/widgets/mini_player.dart';
import '../../shared/widgets/parchment_banner.dart';
import 'widgets/category_card.dart';

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

class _CategorySongsScreenState extends State<CategorySongsScreen> {
  final SongRepository _songRepository = SongRepository();
  final CategoryRepository _categoryRepository =
      CategoryRepository();

  List<Song> _songs = [];
  bool _loading = true;
  bool _loadInProgress = false;
  final Set<int> _selectedSongIds = {};

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    if (_loadInProgress) return;

    _loadInProgress = true;

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final songs = await _songRepository
          .getSongsByCategory(widget.category.id!);

      if (!mounted) return;

      setState(() {
        _songs = songs;
        final availableIds = songs.map((song) => song.id).whereType<int>().toSet();
        _selectedSongIds.removeWhere((id) => !availableIds.contains(id));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load songs: $e')),
      );
    } finally {
      _loadInProgress = false;
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

  void _selectAll() {
    setState(() {
      for (final song in _songs) {
        final id = song.id;
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
        excludedCategoryId: widget.category.id,
      );
      if (!mounted || destinationId == null) return;

      final result = await _songRepository.assignCategoryBulk(ids, destinationId);
      if (!mounted) return;
      setState(_selectedSongIds.clear);
      await _loadSongs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved ${result.moved}; unchanged ${result.unchanged}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to move songs: $e')),
      );
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    return '${duration.inMinutes}:'
        '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
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

  /// Starts the category with the existing playback logic. Playback already
  /// shuffles within the category, so any song can be the first one.
  Future<void> _playCategory() async {
    if (_songs.isEmpty) return;

    await _playSong(_songs[Random().nextInt(_songs.length)]);
  }

  Future<void> _showCategorySelector(Song song) async {
    try {
      final categories =
          await _categoryRepository.getAllCategories();

      if (!mounted) return;

      // Exclude the song's current category.
      final availableCategories = categories
          .where((category) => category.id != song.categoryId)
          .toList();

      if (availableCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No other categories available'),
          ),
        );
        return;
      }

      final selectedCategoryId = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              'Move "${song.title}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableCategories.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = availableCategories[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 19,
                      child: Icon(
                        category.isDefault
                            ? Icons.library_music
                            : category.source == 'manual'
                                ? Icons.folder_special
                                : Icons.music_note,
                        size: 19,
                      ),
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      category.isDefault
                          ? 'System category'
                          : category.source == 'manual'
                              ? 'Custom category'
                              : 'Music genre',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
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
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (!mounted || selectedCategoryId == null) return;

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
        SnackBar(
          content: Text('Failed to update category: $e'),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No songs in this category',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Songs assigned to this category will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
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
            : null,
        title: Text(
          _selectionMode
              ? '${_selectedSongIds.length} selected'
              : widget.category.name,
        ),
        actions: _selectionMode
            ? [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Select all'),
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
            tooltip: 'Refresh songs',
            onPressed: _loadInProgress ? null : _loadSongs,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: ParchmentBanner(
                        icon: categoryIcon(widget.category),
                        title: widget.category.name,
                        subtitle: songCountLabel(_songs.length),
                        playTooltip: 'Play category',
                        onPlay: _selectionMode ? null : _playCategory,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: _songs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(
                          height: 1,
                          indent: 82,
                        ),
                        itemBuilder: (context, index) {
                          final song = _songs[index];

                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectionMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      song.id != null && _selectedSongIds.contains(song.id)
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: song.id != null && _selectedSongIds.contains(song.id)
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline,
                                      size: 22,
                                    ),
                                  ),
                                ArtworkImage(
                              artworkPath: song.artworkPath,
                              size: 52,
                              borderRadius: 10,
                            ),
                              ],
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatDuration(song.duration),
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (!_selectionMode) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Change category',
                                  icon: const Icon(
                                    Icons.drive_file_move_outlined,
                                  ),
                                  onPressed: () =>
                                      _showCategorySelector(song),
                                ),
                              ],
                              ],
                            ),
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
                  ],
                ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}