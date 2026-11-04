
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;
import 'package:saf/saf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';
import 'artwork_service.dart';

class LibraryScannerService {
  final Saf _saf = Saf();
  final SongRepository _songRepository = SongRepository();

  final ArtworkService _artworkService = ArtworkService();

  static const String _libraryUriKey = 'selected_library_uri';

  static const Set<String> _supportedExtensions = {
    '.mp3',
    '.m4a',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
  };

  // Opens the Android folder picker and scans the selected folder.
  // Returns null if the user cancels the picker.
  Future<int?> pickAndScanLibrary() async {
    final directory = await _saf.pickDirectory();

    if (directory == null) {
      return null;
    }

    final permissions = await _saf.persistedPermissions();

    final readablePermissions = permissions
        .where((permission) => permission.read)
        .toList()
      ..sort(
        (a, b) => b.persistedTime.compareTo(a.persistedTime),
      );

    if (readablePermissions.isEmpty) {
      throw Exception('Android did not persist folder permission.');
    }

    final prefs = await SharedPreferences.getInstance();

    // Save Android's actual persisted permission URI.
    await prefs.setString(
      _libraryUriKey,
      readablePermissions.first.uri,
    );

    return scanDirectory(directory.uri);
  }

  // Returns the previously selected folder if permission is still available.
  Future<String?> getSavedLibraryUri() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUri = prefs.getString(_libraryUriKey);

    if (savedUri == null) return null;

    final permissions = await _saf.persistedPermissions();

    final hasPermission = permissions.any(
      (permission) =>
          permission.uri == savedUri && permission.read,
    );

    if (!hasPermission) return null;

    final directory = await _saf.stat(savedUri);

    if (directory == null || !directory.isDir) {
      return null;
    }

    return savedUri;
  }

  // Rescans the previously selected folder.
  Future<int?> rescanSavedLibrary() async {
    final directoryUri = await getSavedLibraryUri();

    if (directoryUri == null) {
      return null;
    }

    return scanDirectory(directoryUri);
  }

  // Recursively scans a selected directory.
  
  Future<int> scanDirectory(String directoryUri) async {
    int scannedCount = 0;

    final tempDir = await Directory.systemTemp.createTemp(
      'mood_music_metadata_',
    );

    try {
      await for (final entry in _saf.walk(directoryUri)) {
        final file = entry.file;

        if (file.isDir) continue;

        final extension = p.extension(file.name).toLowerCase();

        if (!_supportedExtensions.contains(extension)) {
          continue;
        }

        try {
          final localPath = p.join(
            tempDir.path,
            'audio_$scannedCount$extension',
          );

          await _saf.copyToLocalFile(file.uri, localPath);

          // Read basic metadata without extracting artwork.
          final metadata = readMetadata(
            File(localPath),
            getImage: false,
          );

          // Reuse cached artwork whenever possible.
          String? artworkPath =
              await _artworkService.getCachedArtworkPath(file.uri);

          // Extract embedded artwork only when cache is unavailable.
          if (artworkPath == null) {
            final artworkMetadata = readMetadata(
              File(localPath),
              getImage: true,
            );

            artworkPath = await _artworkService.saveArtwork(
              sourceUri: file.uri,
              pictures: artworkMetadata.pictures,
            );
          }

          final title = metadata.title?.trim();
          final artist = metadata.artist?.trim();

          final genre = metadata.genres
              .where((value) => value.trim().isNotEmpty)
              .firstOrNull;

          final song = Song(
            uri: file.uri,
            title: title == null || title.isEmpty
                ? p.basenameWithoutExtension(file.name)
                : title,
            artist: artist == null || artist.isEmpty
                ? 'Unknown Artist'
                : artist,
            album: metadata.album,
            genre: genre,
            duration: metadata.duration?.inSeconds ?? 0,
            categoryId: 0,
            artworkPath: artworkPath,
          );

          await _songRepository.saveScannedSong(song);

          scannedCount++;

          print('Scanned: ${song.title}');
        } catch (e) {
          print('Failed to scan ${file.name}: $e');
        }
      }
    } finally {
      await tempDir.delete(recursive: true);
    }

    print('Library scan completed. Songs scanned: $scannedCount');

    return scannedCount;
  }
}
