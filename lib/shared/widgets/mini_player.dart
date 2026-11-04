
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

import '../../features/player/playback_handler.dart';
import '../../features/player/now_playing_screen.dart';
import 'artwork_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final handler = playbackHandlerInstance;

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;

        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          child: Container(
            height: 76,
            margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NowPlayingScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          ArtworkImage(
                            artworkPath: mediaItem.artUri?.scheme == 'file'
                                ? mediaItem.artUri!.toFilePath()
                                : null,
                            size: 46,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mediaItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mediaItem.artist ?? 'Unknown Artist',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  builder: (context, playbackSnapshot) {
                    final isPlaying =
                        playbackSnapshot.data?.playing ?? false;

                    return IconButton(
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: isPlaying
                          ? handler.pause
                          : handler.play,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    );
                  },
                ),

                IconButton(
                  tooltip: 'Next',
                  onPressed: handler.skipToNext,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
