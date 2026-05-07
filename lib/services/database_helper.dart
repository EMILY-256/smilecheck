import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/scan_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/scans.db';
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE scans(
            id TEXT PRIMARY KEY,
            imagePath TEXT,
            date TEXT,
            toothName TEXT,
            severity TEXT,
            cariesPercentage REAL,
            issues TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertScan(Scan scan) async {
    final db = await database;
    await db.insert('scans', {
      'id': scan.id,
      'imagePath': scan.imagePath,
      'date': scan.date.toIso8601String(),
      'toothName': scan.toothName,
      'severity': scan.severity,
      'cariesPercentage': scan.cariesPercentage,
      'issues': scan.issues.join(','),
    });
  }

  Future<List<Scan>> getScans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('scans', orderBy: 'date DESC');
    return maps.map((map) {
      return Scan(
        id: map['id'],
        imagePath: map['imagePath'],
        date: DateTime.parse(map['date']),
        toothName: map['toothName'],
        severity: map['severity'],
        cariesPercentage: map['cariesPercentage'],
        issues: (map['issues'] as String).split(','),
      );
    }).toList();
  }

  // Authentication methods
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);
    final result = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, hashedPassword],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> registerUser(
      String email, String name, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);
    try {
      final id = await db.insert('users', {
        'email': email,
        'name': name,
        'password_hash': hashedPassword,
        'created_at': DateTime.now().toIso8601String(),
      });
      return {'id': id, 'email': email, 'name': name};
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(User user) async {
    final db = await database;
    final result = await db.update(
      'users',
      {'name': user.name, 'email': user.email},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return result > 0;
  }

  Future<void> logout() async {
    // Clear any session data if needed
  }
}
