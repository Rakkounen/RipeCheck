import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/utils/app_logger.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static const String _dbName = 'ripecheck.db';
  static const int _dbVersion = 2;
  static const String tablePredictions = 'predictions';
  static const String tableUsers = 'users';

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  bool get isInitialized => _database != null && _database!.isOpen;

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    try {
      AppLogger.log('Inisialisasi SQLite database...');
      final dbPath = await getDatabasesPath();
      final fullPath = p.join(dbPath, _dbName);

      final db = await openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: (db, version) async {
          AppLogger.log('Membuat tabel $tableUsers dan $tablePredictions pada SQLite...');
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          AppLogger.log('Migrasi SQLite database dari versi $oldVersion ke $newVersion...');
          await _ensureTablesAndColumns(db);
        },
        onOpen: (db) async {
          // Pastikan tabel dan kolom selalu siap saat database dibuka
          await _ensureTablesAndColumns(db);
        },
      );

      AppLogger.log('SQLite database berhasil dibuka di: $fullPath');
      return db;
    } catch (e, stackTrace) {
      AppLogger.error('Gagal membuka SQLite database', e, stackTrace);
      rethrow;
    }
  }

  static Future<void> _createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePredictions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL DEFAULT '',
        fruitName TEXT NOT NULL,
        ripenessStatus TEXT NOT NULL,
        confidence REAL NOT NULL,
        imagePath TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _ensureTablesAndColumns(Database db) async {
    await _createTables(db);

    // Periksa apakah kolom userId sudah ada di tabel predictions
    try {
      final columns = await db.rawQuery('PRAGMA table_info($tablePredictions)');
      final hasUserId = columns.any((c) => c['name'] == 'userId');
      if (!hasUserId) {
        AppLogger.log('Menambahkan kolom userId ke tabel predictions...');
        await db.execute("ALTER TABLE $tablePredictions ADD COLUMN userId TEXT NOT NULL DEFAULT ''");
      }
    } catch (e) {
      AppLogger.log('Cek kolom userId: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
