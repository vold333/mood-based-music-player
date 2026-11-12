
import 'package:flutter/material.dart';

import '../../data/models/song.dart';
import '../../data/repositories/song_repository.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final SongRepository _songRepository = SongRepository();

  List<Song> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final songs =
          await _songRepository.getAllSongsWithCategory();

      if (!mounted) return;

      setState(() {
        _songs = songs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Music'),
        actions: [
          IconButton(
            onPressed: _loadSongs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh library',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _songs.isEmpty
                  ? const Center(
                      child: Text('No songs found. Scan your music folder.'),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                '${_songs.length} Songs',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _songs.length,
                            itemBuilder: (context, index) {
                              final song = _songs[index];

                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.music_note),
                                ),
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${song.artist ?? "Unknown Artist"}'
                                  ' • ${song.categoryName ?? "Uncategorized"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.more_vert,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
