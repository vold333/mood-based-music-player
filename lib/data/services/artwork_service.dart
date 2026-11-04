
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ArtworkService {
  Future<Directory> get _artworkDirectory async {
    final appDirectory = await getApplicationSupportDirectory();

    final directory = Directory(
      p.join(appDirectory.path, 'album_artwork'),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    return hash;
  }

  Future<File> _getArtworkFile(String sourceUri) async {
    final directory = await _artworkDirectory;

    final filename =
        'artwork_${_stableHash(sourceUri).toRadixString(16)}.img';

    return File(p.join(directory.path, filename));
  }

  Future<String?> getCachedArtworkPath(String sourceUri) async {
    final file = await _getArtworkFile(sourceUri);

    if (!await file.exists()) return null;

    try {
      final bytes = await file.readAsBytes();

      if (!_isValidImage(bytes)) {
        await file.delete();
        return null;
      }

      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> saveArtwork({
    required String sourceUri,
    required List<Picture> pictures,
  }) async {
    final cachedPath = await getCachedArtworkPath(sourceUri);

    if (cachedPath != null) return cachedPath;

    if (pictures.isEmpty) return null;

    Picture? selectedPicture;

    for (final picture in pictures) {
      if (picture.bytes.isNotEmpty &&
          picture.pictureType == PictureType.coverFront) {
        selectedPicture = picture;
        break;
      }
    }

    selectedPicture ??= pictures.cast<Picture?>().firstWhere(
          (picture) => picture!.bytes.isNotEmpty,
          orElse: () => null,
        );

    if (selectedPicture == null) return null;

    final bytes = selectedPicture.bytes;

    if (!_isValidImage(bytes)) return null;

    final file = await _getArtworkFile(sourceUri);
    final temporaryFile = File('${file.path}.tmp');

    try {
      await temporaryFile.writeAsBytes(bytes, flush: true);

      if (await file.exists()) {
        await file.delete();
      }

      await temporaryFile.rename(file.path);

      return file.path;
    } catch (_) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      return null;
    }
  }

  bool _isValidImage(List<int> bytes) {
    if (bytes.length < 8) return false;

    // JPEG
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;

    // PNG
    final isPng = bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;

    // GIF
    final isGif = bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46;

    // WebP
    final isWebP = bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;

    return isJpeg || isPng || isGif || isWebP;
  }
}
