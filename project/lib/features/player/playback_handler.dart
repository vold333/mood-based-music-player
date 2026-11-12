
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/song.dart';
import '../../data/models/category_relationship.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/repositories/category_relationship_repository.dart';

late PlaybackHandler playbackHandlerInstance;

class PlaybackHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  // Expose player streams to the UI.
  Stream<Duration> get positionStream =>
      _player.positionStream;

  Stream<Duration?> get durationStream =>
      _player.durationStream;

  Duration get currentPosition => _player.position;

  final AudioPlayer _player = AudioPlayer();

  final SongRepository _songRepository = SongRepository();

  final CategoryRelationshipRepository _relationshipRepository =
      CategoryRelationshipRepository();

  List<Song> _currentQueue = [];
  int _queueIndex = -1;
  int? _activeCategoryId;

  bool _isAdvancing = false;

  PlaybackHandler() {
    _player.playbackEventStream.listen(_broadcastState);

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        unawaited(_advanceQueue());
      }
    });
  }

  // Start shuffled playback from a selected song's category.
  Future<void> playCategorySong(Song selectedSong) async {
    final songs = await _songRepository.getSongsByCategory(
      selectedSong.categoryId,
    );

    if (songs.isEmpty) return;

    songs.shuffle();

    // Always start with the song selected by the user.
    final selectedIndex = songs.indexWhere(
      (song) => song.uri == selectedSong.uri,
    );

    if (selectedIndex != -1) {
      final selected = songs.removeAt(selectedIndex);
      songs.insert(0, selected);
    }

    _currentQueue = songs;
    _queueIndex = 0;
    _activeCategoryId = selectedSong.categoryId;

    await _playCurrentSong();
  }

  // Backward-compatible entry point.
  Future<void> playSong(Song song) async {
    await playCategorySong(song);
  }

  Future<void> _playCurrentSong() async {
    if (_queueIndex < 0 ||
        _queueIndex >= _currentQueue.length) {
      return;
    }

    final song = _currentQueue[_queueIndex];

    mediaItem.add(
      MediaItem(
      id: song.uri,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album ?? 'Unknown Album',
      duration: Duration(seconds: song.duration),
      artUri: song.artworkPath != null
        ? Uri.file(song.artworkPath!)
        : null,
      ),
    );

    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(song.uri)),
    );

    unawaited(_player.play());
  }

  // Advance within the category, then transition to a related category.
  Future<void> _advanceQueue() async {
    if (_isAdvancing || _activeCategoryId == null) return;

    _isAdvancing = true;

    try {
      if (_queueIndex + 1 < _currentQueue.length) {
        _queueIndex++;
        await _playCurrentSong();
        return;
      }

      await _advanceToRelatedCategory();
    } catch (e) {
      // Stop gracefully if the next track cannot be loaded.
      await stop();
    } finally {
      _isAdvancing = false;
    }
  }

  // Select the highest-priority related category that contains songs.
  Future<void> _advanceToRelatedCategory() async {
    final relationships =
        await _relationshipRepository.getRelatedCategories(
      _activeCategoryId!,
    );

    if (relationships.isEmpty) {
      await stop();
      return;
    }

    final availableCategories =
        <MapEntry<CategoryRelationship, List<Song>>>[];

    for (final relationship in relationships) {
      final songs = await _songRepository.getSongsByCategory(
        relationship.toCategoryId,
      );

      if (songs.isNotEmpty) {
        availableCategories.add(
          MapEntry(relationship, songs),
        );
      }
    }

    if (availableCategories.isEmpty) {
      await stop();
      return;
    }

    final highestPriority = availableCategories
        .map((entry) => entry.key.priority)
        .reduce((a, b) => a < b ? a : b);

    final highestPriorityCategories = availableCategories
        .where((entry) => entry.key.priority == highestPriority)
        .toList();

    // Random selection when multiple categories share top priority.
    highestPriorityCategories.shuffle();

    final selected = highestPriorityCategories.first;

    final previousSongUri = _currentQueue[_queueIndex].uri;

    final nextSongs = selected.value;
    nextSongs.shuffle();

    // Avoid immediately repeating the previous song when possible.
    if (nextSongs.length > 1 &&
        nextSongs.first.uri == previousSongUri) {
      final alternativeIndex = nextSongs.indexWhere(
        (song) => song.uri != previousSongUri,
      );

      if (alternativeIndex > 0) {
        final alternative = nextSongs[alternativeIndex];
        nextSongs[alternativeIndex] = nextSongs.first;
        nextSongs[0] = alternative;
      }
    }

    _currentQueue = nextSongs;
    _queueIndex = 0;
    _activeCategoryId = selected.key.toCategoryId;

    await _playCurrentSong();
  }

  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await _advanceQueue();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queueIndex > 0) {
      _queueIndex--;
      await _playCurrentSong();
    } else if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();

    _currentQueue.clear();
    _queueIndex = -1;
    _activeCategoryId = null;

    mediaItem.add(null);

    await super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    final processingState = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing)
            MediaControl.pause
          else
            MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }
}
