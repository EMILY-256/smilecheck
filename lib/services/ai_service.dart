// lib/services/ai_service.dart

import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

class AiService {
  late Interpreter _interpreter;
  late List<String> _labels;
  static const int _inputSize = 224; // Your model's input size

  Future<void> loadModel() async {
    // Load model from assets
    _interpreter = await Interpreter.fromAsset(
        'assets/models/dental_caries_detection.tflite');

    // Load labels
    final labelsRaw = await rootBundle.loadString('assets/models/labels.txt');
    _labels = labelsRaw.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  /// Predict from an image file
  Future<Map<String, dynamic>> predictFromFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    return predictFromImage(image);
  }

  /// Core prediction logic (same preprocessing as your FastAPI)
  Future<Map<String, dynamic>> predictFromImage(img.Image image) async {
    // 1. Resize to 224x224
    final resized =
        img.copyResize(image, width: _inputSize, height: _inputSize);

    // 2. Convert to tensor [1, 224, 224, 3] with MobileNetV2 preprocessing (range [-1, 1])
    final input = _imageToTensorMobileNetV2(resized);

    // 3. Run inference (output shape depends on your model)
    // Assuming binary classification: output[0][0] = caries probability
    final output = List.filled(1 * 1, 0.0).reshape([1, 1]);
    _interpreter.run(input, output);

    double cariesProb = output[0][0].toDouble();

    // 4. Determine class and confidence
    String predictedClass;
    double confidence;
    if (cariesProb >= 0.5) {
      predictedClass = _labels[1]; // "Caries"
      confidence = cariesProb;
    } else {
      predictedClass = _labels[0]; // "Healthy"
      confidence = 1 - cariesProb;
    }

    return {
      'label': predictedClass,
      'confidence': confidence,
      'caries_probability': cariesProb,
      'healthy_probability': 1 - cariesProb,
    };
  }

  // Preprocessing: scale pixel values from [0,255] to [-1,1] (same as FastAPI)
  List<List<List<double>>> _imageToTensorMobileNetV2(img.Image image) {
    final tensor = List.generate(
      _inputSize,
      (_) => List.generate(
        _inputSize,
        (_) => List.filled(3, 0.0),
      ),
    );

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        tensor[y][x][0] = (pixel.r / 127.5) - 1.0; // R
        tensor[y][x][1] = (pixel.g / 127.5) - 1.0; // G
        tensor[y][x][2] = (pixel.b / 127.5) - 1.0; // B
      }
    }
    return tensor;
  }

  void dispose() {
    _interpreter.close();
  }
}
