
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

import 'app/app.dart';
import 'features/player/playback_handler.dart';

late AudioHandler audioHandler;
late PlaybackHandler playbackHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Initializing AudioService...');

  audioHandler = await AudioService.init(
    builder: () {
      playbackHandlerInstance = PlaybackHandler();
      return playbackHandlerInstance;
    }, 
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.moodmusic.player.audio',
      androidNotificationChannelName: 'Mood Music Playback',
      androidNotificationOngoing: true,
    ),
  );

  debugPrint('AudioService initialized.');

  runApp(const MoodMusicApp());
}