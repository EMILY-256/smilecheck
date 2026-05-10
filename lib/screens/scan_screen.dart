import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/scan_model.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Scan? _latestScan;
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
        _latestScan = null;
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

    setState(() {
      _isAnalyzing = true;
      _latestScan = null;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please sign in again before running a scan';
          _isAnalyzing = false;
        });
        return;
      }
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      final scan = await scanProvider.analyzeImage(
        _selectedImage!,
        _selectedTooth ?? 'Not specified',
        user.id,
      );
      if (scan != null && mounted) {
        setState(() {
          _latestScan = scan;
          _isAnalyzing = false;
        });
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.jpeg',
              height: 30,
              errorBuilder: (_, __, ___) => const Icon(Icons.health_and_safety),
            ),
            const SizedBox(width: 8),
            const Text('New Dental Scan'),
          ],
        ),
      ),
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
            if (_latestScan != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(context, _latestScan!),
            ],
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Scan scan) {
    final accentColor = _resultColor(scan);
    final guidanceTips = _tipsForScan(scan);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _resultIcon(scan),
                color: accentColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _headlineForScan(scan),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Confidence: ${scan.confidence.clamp(0, 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (scan.cariesPercentage != null && scan.resultType == 'caries') ...[
            const SizedBox(height: 4),
            Text(
              'Caries probability: ${scan.cariesPercentage!.toStringAsFixed(1)}%',
            ),
          ],
          const SizedBox(height: 6),
          Text(_explanationForScan(scan)),
          const SizedBox(height: 14),
          const Text(
            'What to do now',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(_nextStepForScan(scan)),
          const SizedBox(height: 14),
          const Text(
            'How to reduce risk',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...guidanceTips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $tip'),
              )),
        ],
      ),
    );
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'mild':
        return Colors.amber.shade800;
      default:
        return Colors.green;
    }
  }

  Color _resultColor(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return Colors.blueGrey;
      case 'caries':
        return _severityColor(scan.severity);
      default:
        return Colors.green;
    }
  }

  IconData _resultIcon(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return Icons.center_focus_weak_rounded;
      case 'caries':
        return Icons.warning_amber_rounded;
      default:
        return Icons.verified_rounded;
    }
  }

  String _headlineForScan(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return 'Image unsuitable for dental analysis';
      case 'caries':
        return 'Possible caries detected';
      default:
        return 'No obvious caries detected';
    }
  }

  String _explanationForScan(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return 'The image did not look clear enough for a dependable dental reading. Retaking the photo should give a more reliable result.';
      case 'caries':
        switch (scan.severity) {
          case 'severe':
            return 'The model found a strong pattern consistent with advanced decay. Professional dental treatment should be arranged soon.';
          case 'moderate':
            return 'The model found a moderate likelihood of decay. This can progress if it is left untreated.';
          default:
            return 'The model found early signs that may match the beginning of caries. Early action usually gives the best outcome.';
        }
      default:
        return 'The model did not find a strong caries pattern in this image. Continue preventive care and monitor for pain, dark spots, or sensitivity.';
    }
  }

  String _nextStepForScan(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return 'Retake the image with the selected tooth centered, in focus, and filling more of the frame.';
      case 'caries':
        switch (scan.severity) {
          case 'severe':
            return 'Book a dental visit as soon as possible, especially if you have pain, swelling, or sensitivity to hot or cold foods.';
          case 'moderate':
            return 'Arrange a dental checkup, improve daily cleaning, and watch for worsening sensitivity or visible discoloration.';
          default:
            return 'Improve oral hygiene now and consider a dental review if the area becomes sensitive or the mark gets darker.';
        }
      default:
        return 'Maintain brushing and flossing habits, limit sugar frequency, and repeat the scan or seek a dental opinion if symptoms appear.';
    }
  }

  List<String> _tipsForScan(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return _retakeTipsForUnsuitable;
      case 'caries':
        return _preventionTipsForCaries;
      default:
        return _preventionTipsForHealthy;
    }
  }

  List<String> get _preventionTipsForCaries => const [
        'Brush twice daily with fluoride toothpaste.',
        'Floss or clean between teeth every day.',
        'Reduce frequent sugary snacks and drinks.',
        'Rinse with water after sweet foods when brushing is not possible.',
      ];

  List<String> get _preventionTipsForHealthy => const [
        'Keep brushing twice daily with fluoride toothpaste.',
        'Clean between teeth daily to remove plaque.',
        'Choose water more often than sugary drinks.',
        'Keep regular dental checkups to catch early changes.',
      ];

  List<String> get _retakeTipsForUnsuitable => const [
        'Move closer so the selected tooth fills most of the frame.',
        'Use bright, even lighting and avoid strong shadows.',
        'Hold the camera steady and keep fingers out of view.',
        'Retake the image if the tooth is blurred or partly blocked.',
      ];
}
