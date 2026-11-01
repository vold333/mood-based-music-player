
import 'package:flutter/material.dart';
import '../features/categories/category_screen.dart';
import '../data/services/library_scanner_service.dart';

class MoodMusicApp extends StatelessWidget {
  const MoodMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const CategoryScreen(),
    );
  }
}

class LibrarySetupScreen extends StatefulWidget {
  const LibrarySetupScreen({super.key});

  @override
  State<LibrarySetupScreen> createState() =>
      _LibrarySetupScreenState();
}

class _LibrarySetupScreenState extends State<LibrarySetupScreen> {
  final LibraryScannerService _scannerService =
      LibraryScannerService();

  String _status = 'No music folder selected';
  bool _loading = false;

  Future<void> selectMusicFolder() async {
    setState(() {
      _loading = true;
      _status = 'Scanning music folder...';
    });

    try {
      final scannedCount =
          await _scannerService.pickAndScanLibrary();

      if (!mounted) return;

      if (scannedCount == null) {
        setState(() {
          _status = 'Folder selection cancelled';
        });
        return;
      }

      setState(() {
        _status = 'Scan completed!\n'
            'Songs saved: $scannedCount';
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
        title: const Text('Mood Music Player'),
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
