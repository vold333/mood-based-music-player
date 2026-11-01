
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
}
