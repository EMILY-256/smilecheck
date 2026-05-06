// lib/providers/scan_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_model.dart';
import '../services/api_service.dart';

class ScanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Scan> _scans = [];
  bool _isAnalyzing = false;
  String? _analysisError;

  List<Scan> get scans => _scans;
  bool get isAnalyzing => _isAnalyzing;
  String? get analysisError => _analysisError;

  // Load existing scans from local SQLite (called after login)
  Future<void> loadScans() async {
    try {
      _scans = await _api.getScans();
      notifyListeners();
    } catch (e) {
      _analysisError = 'Failed to load scan history: $e';
      notifyListeners();
    }
  }

  // Analyze a tooth image using the backend API
  Future<Scan?> analyzeImage(File image, String toothName) async {
    _isAnalyzing = true;
    _analysisError = null;
    notifyListeners();

    try {
      // 1. Check if the image contains a tooth (uses backend confidence)
      final isTooth = await _api.isToothImage(image);
      if (!isTooth) {
        throw Exception('The image does not appear to contain a tooth. Please upload a clear tooth photo.');
      }

      // 2. Run inference and store result
      final scan = await _api.analyzeImage(image, toothName);
      
      // 3. Refresh the local list
      _scans = await _api.getScans();
      _isAnalyzing = false;
      notifyListeners();
      return scan;
    } on SocketException {
      _analysisError = 'Network error: Cannot reach the server. Please check your connection.';
      _isAnalyzing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _analysisError = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      return null;
    }
  }

  // Clear any displayed error
  void clearError() {
    _analysisError = null;
    notifyListeners();
  }
}