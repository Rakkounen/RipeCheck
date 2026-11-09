import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';
import '../../core/utils/app_logger.dart';

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final AppDatabase _appDatabase = AppDatabase();
  static const String _prefCurrentUserKey = 'current_user_data';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Memuat session user yang tersimpan di SharedPreferences
  Future<UserModel?> loadCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(_prefCurrentUserKey);
      if (userDataStr != null) {
        final map = jsonDecode(userDataStr) as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(map);
      }
    } catch (e) {
      AppLogger.error('Gagal memuat sesi user', e);
    }
    return _currentUser;
  }

  /// Pendaftaran akun baru ke database SQLite
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await _appDatabase.database;

    // Cek apakah email sudah terdaftar
    final existing = await db.query(
      AppDatabase.tableUsers,
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (existing.isNotEmpty) {
      throw Exception('Email sudah terdaftar. Silakan masuk atau gunakan email lain.');
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      createdAt: DateTime.now(),
    );

    await db.insert(AppDatabase.tableUsers, newUser.toMap());
    await _saveUserSession(newUser);
    AppLogger.log('Akun baru berhasil didaftarkan: ${newUser.email}');
    return newUser;
  }

  /// Masuk dengan email dan kata sandi
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.query(
      AppDatabase.tableUsers,
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
    );

    if (results.isEmpty) {
      throw Exception('Email atau kata sandi tidak sesuai.');
    }

    final user = UserModel.fromMap(results.first);
    await _saveUserSession(user);
    AppLogger.log('User berhasil masuk: ${user.email}');
    return user;
  }

  /// Keluar dari akun (logout)
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefCurrentUserKey);
    AppLogger.log('User berhasil logout');
  }

  Future<void> _saveUserSession(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCurrentUserKey, jsonEncode(user.toMap()));
  }
}

