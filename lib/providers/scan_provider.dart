import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_model.dart';
import '../services/ai_service.dart';
import '../services/database_helper.dart';

class ScanProvider extends ChangeNotifier {
  final AiService _ai;
  final DatabaseHelper _db = DatabaseHelper();
  List<Scan> _scans = [];
  bool _isAnalyzing = false;
  String? _analysisError;

  ScanProvider({AiService? aiService}) : _ai = aiService ?? AiService();

  List<Scan> get scans => _scans;
  bool get isAnalyzing => _isAnalyzing;
  String? get analysisError => _analysisError;

  Future<void> loadScans() async {
    _scans = await _db.getScans();
    notifyListeners();
  }

  Future<Scan?> analyzeImage(File image, String toothName) async {
    _isAnalyzing = true;
    _analysisError = null;
    notifyListeners();

    try {
      final prediction = await _ai.predictFromFile(image);
      final predictedClass = prediction['label'];
      final confidence = prediction['confidence'];
      final cariesProb = prediction['caries_probability'];

      String severity;
      double cariesPercentage;
      List<String> issues;

      if (predictedClass == 'Caries') {
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

      await _db.insertScan(scan);
      _scans = await _db.getScans();
      _isAnalyzing = false;
      notifyListeners();
      return scan;
    } catch (e) {
      _analysisError = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _analysisError = null;
    notifyListeners();
  }
}
