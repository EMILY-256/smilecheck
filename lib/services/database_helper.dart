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
      version: 2,
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
            userId TEXT NOT NULL,
            imagePath TEXT,
            date TEXT,
            toothName TEXT,
            resultType TEXT NOT NULL,
            severity TEXT,
            confidence REAL,
            cariesPercentage REAL,
            modelLabel TEXT,
            stage1Label TEXT,
            stage1Confidence REAL,
            stage2Label TEXT,
            stage2Confidence REAL,
            issues TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE scans ADD COLUMN userId TEXT NOT NULL DEFAULT ''");
          await db.execute(
              "ALTER TABLE scans ADD COLUMN resultType TEXT NOT NULL DEFAULT 'healthy'");
          await db.execute(
              'ALTER TABLE scans ADD COLUMN confidence REAL NOT NULL DEFAULT 0');
          await db.execute(
              "ALTER TABLE scans ADD COLUMN modelLabel TEXT NOT NULL DEFAULT ''");
          await db.execute(
              "ALTER TABLE scans ADD COLUMN stage1Label TEXT NOT NULL DEFAULT 'Legacy'");
          await db.execute(
              'ALTER TABLE scans ADD COLUMN stage1Confidence REAL NOT NULL DEFAULT 100');
          await db.execute('ALTER TABLE scans ADD COLUMN stage2Label TEXT');
          await db
              .execute('ALTER TABLE scans ADD COLUMN stage2Confidence REAL');
          await db.execute('''
            UPDATE scans
            SET
              resultType = CASE
                WHEN severity = 'healthy' THEN 'healthy'
                ELSE 'caries'
              END,
              confidence = COALESCE(cariesPercentage, 0),
              modelLabel = CASE
                WHEN severity = 'healthy' THEN 'Healthy'
                ELSE 'Caries'
              END,
              stage2Label = CASE
                WHEN severity = 'healthy' THEN 'Healthy'
                ELSE 'Caries'
              END,
              stage2Confidence = COALESCE(cariesPercentage, 0)
          ''');
        }
      },
    );
  }

  Future<void> insertScan(Scan scan) async {
    final db = await database;
    await db.insert('scans', {
      'id': scan.id,
      'userId': scan.userId,
      'imagePath': scan.imagePath,
      'date': scan.date.toIso8601String(),
      'toothName': scan.toothName,
      'resultType': scan.resultType,
      'severity': scan.severity,
      'confidence': scan.confidence,
      'cariesPercentage': scan.cariesPercentage,
      'modelLabel': scan.modelLabel,
      'stage1Label': scan.stage1Label,
      'stage1Confidence': scan.stage1Confidence,
      'stage2Label': scan.stage2Label,
      'stage2Confidence': scan.stage2Confidence,
      'issues': scan.issues.join(','),
    });
  }

  Future<List<Scan>> getScansByUserId(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) {
      return Scan(
        id: map['id'] as String,
        userId: (map['userId'] as String?) ?? '',
        imagePath: (map['imagePath'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        toothName: (map['toothName'] as String?) ?? '',
        resultType: (map['resultType'] as String?) ?? 'healthy',
        severity: map['severity'] as String?,
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
        cariesPercentage: (map['cariesPercentage'] as num?)?.toDouble(),
        modelLabel: (map['modelLabel'] as String?) ?? '',
        stage1Label: (map['stage1Label'] as String?) ?? 'Legacy',
        stage1Confidence: (map['stage1Confidence'] as num?)?.toDouble() ?? 0.0,
        stage2Label: map['stage2Label'] as String?,
        stage2Confidence: (map['stage2Confidence'] as num?)?.toDouble(),
        issues: ((map['issues'] as String?) ?? '')
            .split(',')
            .where((issue) => issue.isNotEmpty)
            .toList(),
      );
    }).toList();
  }

  Future<void> deleteScan(String id) async {
    final db = await database;
    await db.delete('scans', where: 'id = ?', whereArgs: [id]);
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
