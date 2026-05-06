// lib/services/api_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_model.dart';

class ApiService {
  // Change this to your PC's IP when testing on a real device
  static const String baseUrl = 'http://10.10.1.97:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator
  // static const String baseUrl = 'http://192.168.x.x:8000'; // real device

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/dental_scans.db';
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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

  // Convert API prediction to your Scan model
  Future<Scan> analyzeImage(File image, String toothName) async {
    // 1. Call backend
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final json = jsonDecode(responseBody);

    if (response.statusCode != 200) {
      throw Exception(json['detail'] ?? 'Prediction failed');
    }

    // 2. Parse results
    final predictedClass = json['prediction']['class']; // "Caries" or "Healthy"
    final confidence = json['prediction']['confidence'] as double;
    final cariesProb = json['probabilities']['caries'] as double;

    // 3. Convert to your severity and issues
    String severity;
    double cariesPercentage;
    List<String> issues;

    if (predictedClass == 'Caries') {
      // Map confidence to severity (adjust thresholds as needed)
      if (confidence >= 0.8) {
        severity = 'severe';
        issues = ['Deep enamel decay', 'Dentin involvement'];
      } else if (confidence >= 0.6) {
        severity = 'moderate';
        issues = ['Enamel decay', 'Dentin sensitivity'];
      } else {
        severity = 'mild';
        issues = ['Initial enamel demineralization'];
      }
      cariesPercentage = cariesProb * 100;
    } else {
      severity = 'healthy';
      cariesPercentage = (1 - cariesProb) * 100;
      issues = ['No caries detected'];
    }

    // 4. Save image to local storage
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = File('${appDir.path}/$fileName');
    await image.copy(savedImage.path);

    final scan = Scan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: savedImage.path,
      date: DateTime.now(),
      toothName: toothName,
      severity: severity,
      cariesPercentage: cariesPercentage,
      issues: issues,
    );

    // 5. Insert into SQLite
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

    return scan;
  }

  // Get all scans from SQLite
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

  // Check if image contains a tooth (using the model's confidence)
  // If caries confidence is very low and image is not recognised, reject.
  Future<bool> isToothImage(File image) async {
    // Call the backend and check if the prediction is meaningful
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final json = jsonDecode(responseBody);

    if (response.statusCode != 200) return false;

    final confidence = json['prediction']['confidence'] as double;
    // If confidence is too low (<0.5), the model is uncertain – treat as non‑tooth
    return confidence >= 0.5;
  }

}
