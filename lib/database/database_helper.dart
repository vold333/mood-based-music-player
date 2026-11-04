
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'mood_music.db');

    return openDatabase(
      path,
      version: 4,

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: _createTables,

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE songs
            ADD COLUMN category_is_manual INTEGER NOT NULL DEFAULT 0
          ''');
        }

        if (oldVersion < 3) {
          await _createCategoryRelationshipsTable(db);
        }

        if (oldVersion < 4) {
          await db.execute('''
            ALTER TABLE songs
            ADD COLUMN artwork_path TEXT
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE,
        is_default INTEGER NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'genre'
      )
    ''');

    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uri TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        genre TEXT,
        duration INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER NOT NULL,
        category_is_manual INTEGER NOT NULL DEFAULT 0,
        artwork_path TEXT,
        FOREIGN KEY (category_id)
          REFERENCES categories(id)
      )
    ''');

    await db.insert('categories', {
      'name': 'Uncategorized',
      'is_default': 1,
      'source': 'system',
    });

    await _createCategoryRelationshipsTable(db);
  }

  Future<void> _createCategoryRelationshipsTable(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE category_relationships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        from_category_id INTEGER NOT NULL,
        to_category_id INTEGER NOT NULL,

        priority INTEGER NOT NULL DEFAULT 1,

        CHECK (from_category_id != to_category_id),

        UNIQUE (from_category_id, to_category_id),

        FOREIGN KEY (from_category_id)
          REFERENCES categories(id)
          ON DELETE CASCADE,

        FOREIGN KEY (to_category_id)
          REFERENCES categories(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_category_relationships_from
      ON category_relationships(from_category_id)
    ''');
  }
}
