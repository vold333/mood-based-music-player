
import 'package:sqflite/sqflite.dart';

import '../../database/database_helper.dart';
import '../models/song.dart';
import 'category_repository.dart';

class SongRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<Database> get _db async => _databaseHelper.database;

  // Save a scanned song or update its metadata.
  Future<void> saveScannedSong(Song song) async {
    final db = await _db;

    final existingSongs = await db.query(
      'songs',
      where: 'uri = ?',
      whereArgs: [song.uri],
      limit: 1,
    );

    int categoryId;
    bool isManual;

    if (existingSongs.isNotEmpty) {
      final existing = existingSongs.first;

      isManual = existing['category_is_manual'] == 1;

      // Preserve manually assigned categories during rescans.
      if (isManual) {
        categoryId = existing['category_id'] as int;
      } else {
        categoryId = await _categoryRepository
            .getOrCreateGenreCategory(song.genre ?? '');
      }
    } else {
      isManual = false;
      categoryId = await _categoryRepository
          .getOrCreateGenreCategory(song.genre ?? '');
    }

    final songMap = song.toMap()
      ..remove('id')
      ..['category_id'] = categoryId
      ..['category_is_manual'] = isManual ? 1 : 0;

    if (existingSongs.isNotEmpty) {
      await db.update(
        'songs',
        songMap,
        where: 'uri = ?',
        whereArgs: [song.uri],
      );
    } else {
      await db.insert('songs', songMap);
    }
  }

  // Retrieve all songs.
  Future<List<Song>> getAllSongs() async {
    final db = await _db;

    final result = await db.query(
      'songs',
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return result.map((map) => Song.fromMap(map)).toList();
  }

  Future<List<Song>> getAllSongsWithCategory() async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT
        songs.*,
        categories.name AS category_name
      FROM songs
      INNER JOIN categories
        ON songs.category_id = categories.id
      ORDER BY songs.title COLLATE NOCASE ASC
    ''');

    return result.map((map) => Song.fromMap(map)).toList();
  }

  // Retrieve songs belonging to a category.
  Future<List<Song>> getSongsByCategory(int categoryId) async {
    final db = await _db;

    final result = await db.query(
      'songs',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return result.map((map) => Song.fromMap(map)).toList();
  }

  // Manually assign a song to a category.
  Future<void> assignCategory(int songId, int categoryId) async {
    final db = await _db;

    await db.update(
      'songs',
      {
        'category_id': categoryId,
        'category_is_manual': 1,
      },
      where: 'id = ?',
      whereArgs: [songId],
    );
  }


  /// Assigns multiple songs to a category atomically.
  /// Songs already in the destination (or no longer present) are unchanged.
  /// Every moved song is marked manual so rescans preserve the assignment.
  Future<({int moved, int unchanged})> assignCategoryBulk(
    List<int> songIds,
    int categoryId,
  ) async {
    final ids = songIds.toSet().toList();
    if (ids.isEmpty) return (moved: 0, unchanged: 0);

    final db = await _db;

    return db.transaction((txn) async {
      final category = await txn.query(
        'categories',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (category.isEmpty) {
        throw StateError('Destination category not found.');
      }

      var moved = 0;
      var unchanged = 0;
      final batch = txn.batch();

      // Query in small chunks to stay below SQLite bind-variable limits.
      for (var start = 0; start < ids.length; start += 500) {
        final chunk = ids.skip(start).take(500).toList();
        final placeholders = List.filled(chunk.length, '?').join(',');
        final rows = await txn.rawQuery(
          'SELECT id, category_id FROM songs WHERE id IN ($placeholders)',
          chunk,
        );

        final found = <int>{};
        for (final row in rows) {
          final id = row['id'] as int;
          found.add(id);
          if (row['category_id'] == categoryId) {
            unchanged++;
          } else {
            batch.update(
              'songs',
              {
                'category_id': categoryId,
                'category_is_manual': 1,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            moved++;
          }
        }
        unchanged += chunk.length - found.length;
      }

      if (moved > 0) {
        await batch.commit(noResult: true);
      }

      return (moved: moved, unchanged: unchanged);
    });
  }

  // Restore automatic genre-based categorization.
  Future<void> resetCategoryToGenre(Song song) async {
    final categoryId = await _categoryRepository
        .getOrCreateGenreCategory(song.genre ?? '');

    final db = await _db;

    await db.update(
      'songs',
      {
        'category_id': categoryId,
        'category_is_manual': 0,
      },
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  // Delete a song from the app database only.
  Future<void> deleteSong(int songId) async {
    final db = await _db;

    await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

    // Remove songs that no longer exist in the successfully scanned folder.
  Future<void> deleteSongsNotInUris(Set<String> existingUris) async {
    final db = await _db;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: ['id', 'uri'],
      );

      final batch = txn.batch();
      var staleCount = 0;

      for (final row in rows) {
        final uri = row['uri'] as String?;

        if (uri == null || !existingUris.contains(uri)) {
          batch.delete(
            'songs',
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          staleCount++;
        }
      }

      if (staleCount > 0) {
        await batch.commit(noResult: true);
      }
    });
  }
}
