
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../app/theme/glass_tokens.dart';
import '../../app/theme/soul_tokens.dart';
import '../../shared/widgets/artwork_hero.dart';
import '../../shared/widgets/glass_surface.dart';
import '../../shared/widgets/status_pill.dart';
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
    final glass = context.glass;

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
      body: Stack(
        children: [
          const Positioned.fill(child: GrandLineBackdrop()),
          StreamBuilder<MediaItem?>(
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
                  // Scrolls on short screens, centred on tall ones. The wave
                  // strip below sits outside it, so it never overlaps the
                  // controls.
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
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      // Original embedded artwork, never
                                      // cropped and never filtered. Only the
                                      // frame around it is styled.
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 320,
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: scheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: glass.oceanBlue
                                                      .withValues(alpha: 0.30),
                                                  blurRadius: 36,
                                                  offset: const Offset(0, 16),
                                                ),
                                              ],
                                            ),
                                            child: DecoratedBox(
                                              position:
                                                  DecorationPosition.foreground,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                                border: Border.all(
                                                  color: scheme.outlineVariant,
                                                ),
                                              ),
                                              child: LayoutBuilder(
                                                builder: (context, box) {
                                                  return NowPlayingArtworkHero(
                                                    artworkPath: artworkPath,
                                                    size: box.maxWidth,
                                                    borderRadius: 28,
                                                    fit: BoxFit.contain,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // One glass panel holds everything the
                                      // listener reads or touches.
                                      GlassSurface(
                                        radius: 28,
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          18,
                                          20,
                                          16,
                                        ),
                                        child: Column(
                                          children: [
                                            // Song information.
                                            SizedBox(
                                              width: double.infinity,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    mediaItem.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.titleLarge
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: scheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    mediaItem.artist ??
                                                        'Unknown Artist',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 14),

                                            // Playback progress.
                                            StreamBuilder<Duration?>(
                                              stream: handler.durationStream,
                                              initialData: mediaItem.duration,
                                              builder:
                                                  (context, durationSnapshot) {
                                                final duration =
                                                    durationSnapshot.data ??
                                                        mediaItem.duration ??
                                                        Duration.zero;

                                                return StreamBuilder<Duration>(
                                                  stream:
                                                      handler.positionStream,
                                                  initialData:
                                                      handler.currentPosition,
                                                  builder: (context,
                                                      positionSnapshot) {
                                                    final position =
                                                        positionSnapshot.data ??
                                                            Duration.zero;

                                                    final maxDuration =
                                                        duration.inMilliseconds >
                                                                0
                                                            ? duration
                                                                .inMilliseconds
                                                                .toDouble()
                                                            : 1.0;

                                                    final sliderValue = position
                                                        .inMilliseconds
                                                        .toDouble()
                                                        .clamp(
                                                            0.0, maxDuration);

                                                    final timeStyle = theme
                                                        .textTheme.labelMedium
                                                        ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    );

                                                    return Column(
                                                      children: [
                                                        SliderTheme(
                                                          data: SliderTheme.of(
                                                                  context)
                                                              .copyWith(
                                                            trackHeight: 5,
                                                            activeTrackColor:
                                                                glass
                                                                    .oceanBlue,
                                                            inactiveTrackColor:
                                                                scheme.outline,
                                                            thumbColor: context
                                                                .soul
                                                                .accentText,
                                                            overlayColor: context
                                                                .soul
                                                                .accentText
                                                                .withValues(
                                                                    alpha:
                                                                        0.14),
                                                            thumbShape:
                                                                const RoundSliderThumbShape(
                                                              enabledThumbRadius:
                                                                  8,
                                                            ),
                                                          ),
                                                          child: Slider(
                                                            value: sliderValue,
                                                            max: maxDuration,
                                                            onChanged: duration
                                                                        .inMilliseconds >
                                                                    0
                                                                ? (value) {
                                                                    handler
                                                                        .seek(
                                                                      Duration(
                                                                        milliseconds:
                                                                            value
                                                                                .round(),
                                                                      ),
                                                                    );
                                                                  }
                                                                : null,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                _formatDuration(
                                                                    position),
                                                                style:
                                                                    timeStyle,
                                                              ),
                                                              Text(
                                                                _formatDuration(
                                                                    duration),
                                                                style:
                                                                    timeStyle,
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

                                            const SizedBox(height: 12),

                                            // Playback controls.
                                            StreamBuilder<PlaybackState>(
                                              stream: handler.playbackState,
                                              builder: (context, snapshot) {
                                                final isPlaying =
                                                    snapshot.data?.playing ??
                                                        false;

                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Previous',
                                                      iconSize: 34,
                                                      color: scheme.onSurface,
                                                      onPressed: handler
                                                          .skipToPrevious,
                                                      icon: const Icon(
                                                        Icons
                                                            .skip_previous_rounded,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 24),
                                                    DecoratedBox(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: scheme
                                                                .primary
                                                                .withValues(
                                                                    alpha:
                                                                        0.32),
                                                            blurRadius: 20,
                                                            offset:
                                                                const Offset(
                                                                    0, 8),
                                                          ),
                                                        ],
                                                      ),
                                                      child: IconButton.filled(
                                                        tooltip: isPlaying
                                                            ? 'Pause'
                                                            : 'Play',
                                                        iconSize: 38,
                                                        padding:
                                                            const EdgeInsets
                                                                .all(18),
                                                        onPressed: isPlaying
                                                            ? handler.pause
                                                            : handler.play,
                                                        icon: Icon(
                                                          isPlaying
                                                              ? Icons
                                                                  .pause_rounded
                                                              : Icons
                                                                  .play_arrow_rounded,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 24),
                                                    IconButton(
                                                      tooltip: 'Next',
                                                      iconSize: 34,
                                                      color: scheme.onSurface,
                                                      onPressed:
                                                          handler.skipToNext,
                                                      icon: const Icon(
                                                        Icons
                                                            .skip_next_rounded,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),

                                            const SizedBox(height: 18),

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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}