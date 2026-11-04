
import 'package:flutter/material.dart';

import '../../data/models/song.dart';
import '../../data/repositories/song_repository.dart';
import '../../shared/widgets/artwork_image.dart';
import '../../shared/widgets/mini_player.dart';
import '../player/playback_handler.dart';
import '../player/now_playing_screen.dart';

enum SongSortOption {
  title,
  artist,
  duration,
}

class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  final SongRepository _songRepository = SongRepository();
  final TextEditingController _searchController =
      TextEditingController();

  List<Song> _songs = [];
  bool _loading = true;
  SongSortOption _sortOption = SongSortOption.title;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSongs();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    if (_loading == false) {
      setState(() => _loading = true);
    }

    try {
      final songs = await _songRepository.getAllSongsWithCategory();

      if (!mounted) return;

      setState(() {
        _songs = songs;
        _sortSongs();
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

  void _sortSongs() {
    switch (_sortOption) {
      case SongSortOption.title:
        _songs.sort(
          (a, b) => a.title.toLowerCase().compareTo(
                b.title.toLowerCase(),
              ),
        );
        break;

      case SongSortOption.artist:
        _songs.sort(
          (a, b) => (a.artist ?? 'Unknown Artist')
              .toLowerCase()
              .compareTo(
                (b.artist ?? 'Unknown Artist').toLowerCase(),
              ),
        );
        break;

      case SongSortOption.duration:
        _songs.sort(
          (a, b) => b.duration.compareTo(a.duration),
        );
        break;
    }
  }

  List<Song> get _filteredSongs {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return _songs;

    return _songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          (song.artist ?? '').toLowerCase().contains(query) ||
          (song.album ?? '').toLowerCase().contains(query) ||
          (song.categoryName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    return '${duration.inMinutes}:'
        '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String get _sortLabel {
    switch (_sortOption) {
      case SongSortOption.title:
        return 'Title';
      case SongSortOption.artist:
        return 'Artist';
      case SongSortOption.duration:
        return 'Longest first';
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

  void _changeSort(SongSortOption option) {
    setState(() {
      _sortOption = option;
      _sortSongs();
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = _filteredSongs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Songs'),
        actions: [
          PopupMenuButton<SongSortOption>(
            tooltip: 'Sort songs',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sortOption,
            onSelected: _changeSort,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: SongSortOption.title,
                child: Text('Sort by title'),
              ),
              PopupMenuItem(
                value: SongSortOption.artist,
                child: Text('Sort by artist'),
              ),
              PopupMenuItem(
                value: SongSortOption.duration,
                child: Text('Longest first'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadSongs,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? _buildEmptyState(
                  icon: Icons.library_music_outlined,
                  title: 'Your library is empty',
                  subtitle:
                      'Import a music folder to discover your songs.',
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search songs, artists, albums...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _searchController.clear,
                                )
                              : null,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${songs.length} songs',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Spacer(),
                          Text(
                            'Sorted by $_sortLabel',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: songs.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No matching songs',
                              subtitle:
                                  'Try another song, artist or album name.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 12,
                              ),
                              itemCount: songs.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(
                                height: 1,
                                indent: 80,
                              ),
                              itemBuilder: (context, index) {
                                final song = songs[index];

                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 5,
                                  ),
                                  leading: ArtworkImage(
                                    artworkPath: song.artworkPath,
                                    size: 52,
                                    borderRadius: 10,
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.artist ?? 'Unknown Artist',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        song.categoryName ?? 'Uncategorized',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    _formatDuration(song.duration),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  onTap: () => _playSong(song),
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
