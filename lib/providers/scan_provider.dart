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

  Future<void> loadScansForUser(String userId) async {
    _scans = await _db.getScansByUserId(userId);
    notifyListeners();
  }

  Future<Scan?> analyzeImage(
      File image, String toothName, String userId) async {
    _isAnalyzing = true;
    _analysisError = null;
    notifyListeners();

    try {
      final prediction = await _ai.predictFromFile(image);
      final resultType = prediction['result_type'] as String;
      final confidence = (prediction['confidence'] as num).toDouble();
      final stage1Label = prediction['stage1_label'] as String;
      final stage1Confidence =
          (prediction['stage1_confidence'] as num).toDouble();
      final stage2Label = prediction['stage2_label'] as String?;
      final stage2Confidence =
          (prediction['stage2_confidence'] as num?)?.toDouble();
      final cariesPercentage =
          (prediction['caries_probability'] as num?)?.toDouble();

      final severity =
          _resolveSeverity(resultType, stage2Confidence ?? confidence);
      final issues = _issuesForResult(resultType, severity);

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');
      await image.copy(savedImage.path);

      final scan = Scan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        imagePath: savedImage.path,
        date: DateTime.now(),
        toothName: toothName,
        resultType: resultType,
        severity: severity,
        confidence: confidence,
        cariesPercentage: cariesPercentage,
        modelLabel: prediction['model_label'] as String,
        stage1Label: stage1Label,
        stage1Confidence: stage1Confidence,
        stage2Label: stage2Label,
        stage2Confidence: stage2Confidence,
        issues: issues,
      );

      await _db.insertScan(scan);
      _scans = await _db.getScansByUserId(userId);
      _isAnalyzing = false;
      notifyListeners();
      return scan;
    } catch (e) {
      _analysisError = _toUserFriendlyError(e);
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  String? _resolveSeverity(String resultType, double confidence) {
    if (resultType != 'caries') {
      return null;
    }
    if (confidence >= 85) {
      return 'severe';
    }
    if (confidence >= 65) {
      return 'moderate';
    }
    return 'mild';
  }

  List<String> _issuesForResult(String resultType, String? severity) {
    switch (resultType) {
      case 'unsuitable':
        return const [
          'Retake the image with the tooth filling most of the frame',
          'Use steady focus and brighter, even lighting',
          'Avoid fingers, cheeks, and background objects in view',
        ];
      case 'healthy':
        return const [
          'No obvious caries detected',
          'Keep brushing twice daily with fluoride toothpaste',
          'Floss daily and watch for new sensitivity or dark spots',
        ];
      case 'caries':
        switch (severity) {
          case 'severe':
            return const ['Deep enamel decay', 'Dentin involvement'];
          case 'moderate':
            return const ['Enamel decay', 'Dentin sensitivity'];
          default:
            return const ['Initial enamel demineralization'];
        }
      default:
        return const ['Analysis result unavailable'];
    }
  }

  String _toUserFriendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Failed precondition')) {
      return 'The model could not process this image with the current tensor settings. The inference pipeline needs adjustment.';
    }
    if (message.contains('Failed to decode image')) {
      return 'The selected image could not be read. Please try a clearer photo or another file.';
    }
    if (message.contains('not loaded')) {
      return 'The AI model is not ready yet. Restart the app and try again.';
    }
    return message;
  }

  Future<void> deleteScan(String id, String userId) async {
    await _db.deleteScan(id);
    _scans = await _db.getScansByUserId(userId);
    notifyListeners();
  }

  void clearError() {
    _analysisError = null;
    notifyListeners();
  }
}
