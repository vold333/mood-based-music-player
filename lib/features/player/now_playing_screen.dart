
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../shared/widgets/artwork_image.dart';
import 'playback_handler.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final handler = playbackHandlerInstance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: StreamBuilder<MediaItem?>(
        stream: handler.mediaItem,
        builder: (context, mediaSnapshot) {
          final mediaItem = mediaSnapshot.data;

          if (mediaItem == null) {
            return const Center(
              child: Text('Nothing is playing'),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Album artwork placeholder.
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: ArtworkImage(
                        artworkPath: mediaItem.artUri?.scheme == 'file'
                            ? mediaItem.artUri!.toFilePath()
                            : null,
                        size: 340,
                        borderRadius: 24,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Song information.
                Text(
                  mediaItem.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  mediaItem.artist ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),

                const SizedBox(height: 32),

                // Playback progress.
                StreamBuilder<Duration?>(
                  stream: handler.durationStream,
                  initialData: mediaItem.duration,
                  builder: (context, durationSnapshot) {
                    final duration =
                        durationSnapshot.data ?? mediaItem.duration ??
                            Duration.zero;

                    return StreamBuilder<Duration>(
                      stream: handler.positionStream,
                      initialData: handler.currentPosition,
                      builder: (context, positionSnapshot) {
                        final position =
                            positionSnapshot.data ?? Duration.zero;

                        final maxDuration =
                            duration.inMilliseconds > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0;

                        final sliderValue = position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, maxDuration);

                        return Column(
                          children: [
                            Slider(
                              value: sliderValue,
                              max: maxDuration,
                              onChanged: duration.inMilliseconds > 0
                                  ? (value) {
                                      handler.seek(
                                        Duration(
                                          milliseconds: value.round(),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position)),
                                  Text(_formatDuration(duration)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Playback controls.
                StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  builder: (context, snapshot) {
                    final isPlaying =
                        snapshot.data?.playing ?? false;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 34,
                          onPressed: handler.skipToPrevious,
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                          ),
                        ),

                        const SizedBox(width: 24),

                        IconButton.filled(
                          iconSize: 38,
                          padding: const EdgeInsets.all(18),
                          onPressed: isPlaying
                              ? handler.pause
                              : handler.play,
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),

                        const SizedBox(width: 24),

                        IconButton(
                          iconSize: 34,
                          onPressed: handler.skipToNext,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shuffle_rounded,
                      size: 18,
                      color: Colors.deepPurpleAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Category Shuffle',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
