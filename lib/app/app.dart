import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/services/library_scanner_service.dart';
import '../features/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class MoodMusicApp extends StatelessWidget {
  const MoodMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Soul King',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.day,
          darkTheme: AppTheme.night,
          themeMode: themeController.mode,
          builder: (context, child) => _SystemBarsStyle(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SoulSplashScreen(),
        );
      },
    );
  }
}

/// Keeps the status bar and navigation bar icons readable on the active theme.
class _SystemBarsStyle extends StatelessWidget {
  const _SystemBarsStyle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBrightness =
        theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: theme.brightness,
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}

class LibrarySetupScreen extends StatefulWidget {
  const LibrarySetupScreen({super.key});

  @override
  State<LibrarySetupScreen> createState() => _LibrarySetupScreenState();
}

class _LibrarySetupScreenState extends State<LibrarySetupScreen> {
  final LibraryScannerService _scannerService = LibraryScannerService();

  String _status = 'No music folder selected';
  bool _loading = false;

  Future<void> selectMusicFolder() async {
    setState(() {
      _loading = true;
      _status = 'Scanning music folder...';
    });

    try {
      final scannedCount = await _scannerService.pickAndScanLibrary();

      if (!mounted) return;

      if (scannedCount == null) {
        setState(() {
          _status = 'Folder selection cancelled';
        });
        return;
      }

      setState(() {
        _status = 'Scan completed!\nSongs saved: $scannedCount';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soul King Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.library_music, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Music Library Scanner',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : selectMusicFolder,
              icon: const Icon(Icons.folder_open),
              label: Text(
                _loading ? 'Scanning...' : 'Select Music Folder',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
