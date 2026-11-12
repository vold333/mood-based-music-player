
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../shared/widgets/artwork_hero.dart';
import '../../shared/widgets/status_pill.dart';
import '../../shared/widgets/wave_strip.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          iconSize: 32,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
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

          final artworkPath = mediaItem.artUri?.scheme == 'file'
              ? mediaItem.artUri!.toFilePath()
              : null;

          return Column(
            children: [
              // Scrolls on short screens, centred on tall ones. The wave strip
              // below sits outside it, so it never overlaps the controls.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
                            vertical: 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                              // Original embedded artwork, never cropped.
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 340),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: DecoratedBox(
                  decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scheme.primary
                                              .withValues(alpha: 0.28),
                                          blurRadius: 32,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: DecoratedBox(
                                      position: DecorationPosition.foreground,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        border: Border.all(
                                          color: scheme.outlineVariant,
                                        ),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, box) {
                                          return NowPlayingArtworkHero(
                                            artworkPath: artworkPath,
                                            size: box.maxWidth,
                        borderRadius: 24,
                                            fit: BoxFit.contain,
                                          );
                                        },
                                      ),
                      ),
                    ),
                  ),
                ),

                              const SizedBox(height: 28),

                // Song information.
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                Text(
                  mediaItem.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                                    const SizedBox(height: 6),
                Text(
                  mediaItem.artist ?? 'Unknown Artist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                      ),
                ),

                              const SizedBox(height: 20),

                // Playback progress.
                StreamBuilder<Duration?>(
                  stream: handler.durationStream,
                  initialData: mediaItem.duration,
                  builder: (context, durationSnapshot) {
                                  final duration = durationSnapshot.data ??
                                      mediaItem.duration ??
                            Duration.zero;

                    return StreamBuilder<Duration>(
                      stream: handler.positionStream,
                      initialData: handler.currentPosition,
                      builder: (context, positionSnapshot) {
                        final position =
                                          positionSnapshot.data ??
                                              Duration.zero;

                        final maxDuration =
                            duration.inMilliseconds > 0
                                              ? duration.inMilliseconds
                                                  .toDouble()
                                : 1.0;

                                      final sliderValue = position
                                          .inMilliseconds
                            .toDouble()
                            .clamp(0.0, maxDuration);

                                      final timeStyle = theme
                                          .textTheme.labelMedium
                                          ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      );

                        return Column(
                          children: [
                            Slider(
                              value: sliderValue,
                              max: maxDuration,
                                            onChanged: duration
                                                        .inMilliseconds >
                                                    0
                                  ? (value) {
                                      handler.seek(
                                        Duration(
                                                        milliseconds:
                                                            value.round(),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                            Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                children: [
                                                Text(
                                                  _formatDuration(position),
                                                  style: timeStyle,
                                                ),
                                                Text(
                                                  _formatDuration(duration),
                                                  style: timeStyle,
                                                ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                              const SizedBox(height: 16),

                // Playback controls.
                StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  builder: (context, snapshot) {
                    final isPlaying =
                        snapshot.data?.playing ?? false;

                    return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                      children: [
                        IconButton(
                                        tooltip: 'Previous',
                          iconSize: 34,
                          onPressed: handler.skipToPrevious,
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                          ),
                        ),

                        const SizedBox(width: 24),

                        IconButton.filled(
                                        tooltip: isPlaying ? 'Pause' : 'Play',
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
                                        tooltip: 'Next',
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

                              // Read-only status, not a control.
                              const StatusPill(
                                icon: Icons.shuffle_rounded,
                                label: 'Category Shuffle',
                                semanticsLabel:
                                    'Playback mode: category shuffle',
                    ),
                  ],
                ),
                        ),
                      ),
                    );
                  },
                ),
            ),

              const WaveStrip(),
            ],
          );
        },
      ),
    );
  }
}