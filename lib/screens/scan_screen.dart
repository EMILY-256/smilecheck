import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _errorMessage;

  String? _selectedTooth;
  final List<String> _toothOptions = [
    'Upper Right Molar',
    'Upper Right Premolar',
    'Upper Right Canine',
    'Upper Right Incisor',
    'Upper Left Incisor',
    'Upper Left Canine',
    'Upper Left Premolar',
    'Upper Left Molar',
    'Lower Left Molar',
    'Lower Left Premolar',
    'Lower Left Canine',
    'Lower Left Incisor',
    'Lower Right Incisor',
    'Lower Right Canine',
    'Lower Right Premolar',
    'Lower Right Molar',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      setState(() {
        _selectedImage = File(image.path);
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      setState(
          () => _errorMessage = 'Please take a photo or select an image first');
      return;
    }
    if (_selectedTooth == null) {
      setState(() => _errorMessage = 'Please select a tooth from the list');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      final scan =
          await scanProvider.analyzeImage(_selectedImage!, _selectedTooth!);
      if (scan != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan complete: ${scan.severity.toUpperCase()}'),
            backgroundColor:
                scan.severity == 'healthy' ? Colors.green : Colors.orange,
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = scanProvider.analysisError ?? 'Analysis failed';
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Dental Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTooth,
              hint: const Text('Select a tooth'),
              decoration: const InputDecoration(
                labelText: 'Tooth',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              items: _toothOptions
                  .map((tooth) =>
                      DropdownMenuItem(value: tooth, child: Text(tooth)))
                  .toList(),
              onTap: () => FocusScope.of(context).unfocus(),
              onChanged: _isAnalyzing
                  ? null
                  : (value) => setState(() => _selectedTooth = value),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedImage != null)
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!,
                      height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Text(_errorMessage!,
                    style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
            const SizedBox(height: 24),
SizedBox(
  height: 52,
  child: ElevatedButton(
    onPressed: _isAnalyzing ? null : _analyzeImage,
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white, // ensures text is visible
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: _isAnalyzing
        ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Analyzing...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          )
        : const Text(
            'Analyze',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
  ),
)
          ],
        ),
      ),
    );
  }
}
