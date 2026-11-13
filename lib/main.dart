
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

import 'app/app.dart';
import 'app/theme/theme_controller.dart';
import 'features/player/playback_handler.dart';
import 'package:permission_handler/permission_handler.dart';

late AudioHandler audioHandler;
late PlaybackHandler playbackHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Initializing AudioService...');

  await Permission.notification.request();

  audioHandler = await AudioService.init(
    builder: () {
      playbackHandlerInstance = PlaybackHandler();
      return playbackHandlerInstance;
    }, 
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.moodmusic.player.audio',
      androidNotificationChannelName: 'Soul King Playback',
      androidNotificationOngoing: true,
    ),
  );

  debugPrint('AudioService initialized.');

  themeController = await ThemeController.load();

  runApp(const MoodMusicApp());
}