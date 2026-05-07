import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class AiService {
  late Interpreter _interpreter;
  late List<String> _labels;
  static const int _inputSize = 224;

  Future<void> loadModel() async {
    // Copy model from assets to local storage to avoid compression issues
    final modelFile = await _getModelFile('dental_caries_detection.tflite');
    _interpreter = await Interpreter.fromFile(modelFile);

    final labelsRaw = await rootBundle.loadString('assets/models/labels.txt');
    _labels = labelsRaw.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  Future<File> _getModelFile(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$assetPath');
    if (!await file.exists()) {
      final byteData = await rootBundle.load('assets/models/$assetPath');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    return file;
  }

  Future<Map<String, dynamic>> predictFromFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    return predictFromImage(image);
  }

  Future<Map<String, dynamic>> predictFromImage(img.Image image) async {
    final resized =
        img.copyResize(image, width: _inputSize, height: _inputSize);
    final input = _imageToTensorMobileNetV2(resized);

    // Output shape: [1, 1] (binary classification)
    final output = List.filled(1 * 1, 0.0).reshape([1, 1]);
    _interpreter.run(input, output);

    double cariesProb = output[0][0].toDouble();
    String predictedClass;
    double confidence;
    if (cariesProb >= 0.5) {
      predictedClass = _labels.length > 1 ? _labels[1] : "Caries";
      confidence = cariesProb;
    } else {
      predictedClass = _labels.isNotEmpty ? _labels[0] : "Healthy";
      confidence = 1 - cariesProb;
    }

    return {
      'label': predictedClass,
      'confidence': confidence,
      'caries_probability': cariesProb,
      'healthy_probability': 1 - cariesProb,
    };
  }

  List<List<List<List<double>>>> _imageToTensorMobileNetV2(img.Image image) {
    final tensor = List.generate(
      _inputSize,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(3, (_) => 0.0),
      ),
    );
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        tensor[y][x][0] = (pixel.r.toDouble() / 127.5) - 1.0;
        tensor[y][x][1] = (pixel.g.toDouble() / 127.5) - 1.0;
        tensor[y][x][2] = (pixel.b.toDouble() / 127.5) - 1.0;
      }
    }
    return [tensor];
  }

  void dispose() {
    _interpreter.close();
  }
}
