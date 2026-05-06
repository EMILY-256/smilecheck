import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/dental_auth.db';
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>?> registerUser(String email, String name, String password) async {
    final db = await database;
    final hashed = _hashPassword(password);
    try {
      final id = await db.insert('users', {
        'email': email,
        'name': name,
        'password_hash': hashed,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _secureStorage.write(key: 'session_token', value: email);
      return {'id': id, 'email': email, 'name': name};
    } catch (e) {
      return null; // email exists
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (users.isEmpty) return null;
    final user = users.first;
    if (user['password_hash'] != _hashPassword(password)) return null;
    await _secureStorage.write(key: 'session_token', value: email);
    return {'id': user['id'], 'email': user['email'], 'name': user['name']};
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'session_token');
  }

  Future<bool> updateUser(User user) async {
    final db = await database;
    final result = await db.update(
      'users',
      {'name': user.name},
      where: 'email = ?',
      whereArgs: [user.email],
    );
    return result > 0;
  }
}