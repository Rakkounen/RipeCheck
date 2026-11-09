import '../database/app_database.dart';
import '../models/fruit_prediction_model.dart';
import 'auth_repository.dart';
import '../../core/utils/app_logger.dart';

class PredictionRepository {
  static final PredictionRepository _instance = PredictionRepository._internal();
  factory PredictionRepository() => _instance;
  PredictionRepository._internal();

  final AppDatabase _appDatabase = AppDatabase();
  final AuthRepository _authRepository = AuthRepository();

  /// Mengambil semua riwayat pemindaian untuk user yang sedang aktif
  /// Jika user terdaftar, hanya riwayat miliknya yang ditampilkan agar tidak membingungkan
  Future<List<FruitPredictionModel>> getHistory() async {
    try {
      final db = await _appDatabase.database;
      final currentUser = await _authRepository.loadCurrentUser();

      List<Map<String, dynamic>> maps;
      if (currentUser != null && currentUser.id.isNotEmpty) {
        // Filter spesifik berdasarkan ID user yang login
        maps = await db.query(
          AppDatabase.tablePredictions,
          where: 'userId = ? OR userId = ?',
          whereArgs: [currentUser.id, ''],
          orderBy: 'createdAt DESC',
        );
      } else {
        // Jika belum ada user tertentu, ambil semua riwayat umum
        maps = await db.query(
          AppDatabase.tablePredictions,
          orderBy: 'createdAt DESC',
        );
      }

      return maps.map((map) => FruitPredictionModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Gagal mengambil riwayat scan dari SQLite', e, stackTrace);
      return [];
    }
  }

  /// Menyimpan hasil pemindaian baru ke dalam database SQLite per-user
  Future<void> savePrediction(FruitPredictionModel prediction) async {
    try {
      final db = await _appDatabase.database;
      final currentUser = await _authRepository.loadCurrentUser();
      final effectiveUserId = currentUser?.id ?? prediction.userId;

      final updatedPrediction = FruitPredictionModel(
        id: prediction.id,
        userId: effectiveUserId,
        fruitName: prediction.fruitName,
        ripenessStatus: prediction.ripenessStatus,
        confidence: prediction.confidence,
        imagePath: prediction.imagePath,
        createdAt: prediction.createdAt,
      );

      await db.insert(
        AppDatabase.tablePredictions,
        updatedPrediction.toMap(),
      );
      AppLogger.log('Hasil prediksi berhasil disimpan ke SQLite untuk User ($effectiveUserId) dengan ID: ${prediction.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Gagal menyimpan hasil prediksi ke SQLite', e, stackTrace);
      rethrow;
    }
  }

  /// Menghapus satu data pemindaian berdasarkan id
  Future<void> deletePrediction(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        AppDatabase.tablePredictions,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.log('Data prediksi ID $id berhasil dihapus dari SQLite');
    } catch (e, stackTrace) {
      AppLogger.error('Gagal menghapus data prediksi dari SQLite', e, stackTrace);
      rethrow;
    }
  }

  /// Menghapus seluruh riwayat pemindaian milik user yang sedang aktif
  Future<void> clearHistory() async {
    try {
      final db = await _appDatabase.database;
      final currentUser = await _authRepository.loadCurrentUser();

      if (currentUser != null && currentUser.id.isNotEmpty) {
        await db.delete(
          AppDatabase.tablePredictions,
          where: 'userId = ?',
          whereArgs: [currentUser.id],
        );
      } else {
        await db.delete(AppDatabase.tablePredictions);
      }
      AppLogger.log('Riwayat prediksi di SQLite berhasil dibersihkan');
    } catch (e, stackTrace) {
      AppLogger.error('Gagal membersihkan riwayat prediksi di SQLite', e, stackTrace);
      rethrow;
    }
  }
}
