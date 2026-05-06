import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/scan_provider.dart';
import '../models/scan_model.dart';

class AnalysisScreen extends StatefulWidget {
  final File imageFile;
  final String toothName;

  const AnalysisScreen({super.key, required this.imageFile, required this.toothName});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Scan? _scanResult;
  bool _analyzed = false;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    final scan = await scanProvider.analyzeImage(widget.imageFile, widget.toothName);
    if (mounted) {
      setState(() {
        _scanResult = scan;
        _analyzed = true;
      });
      if (scan == null && scanProvider.analysisError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(scanProvider.analysisError!), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  void _shareResult() {
    if (_scanResult == null) return;
    Share.share(
      'Dental Scan Results:\nTooth: ${_scanResult!.toothName}\nSeverity: ${_scanResult!.severity}\nCaries: ${_scanResult!.cariesPercentage.toStringAsFixed(1)}%\nIssues: ${_scanResult!.issues.join(", ")}',
      subject: 'My Dental Scan Report',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    if (scanProvider.isAnalyzing || !_analyzed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analyzing...')),
        body: const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('AI is analyzing your tooth image...'),
          ],
        )),
      );
    }
    if (_scanResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis Failed')),
        body: Center(child: Text(scanProvider.analysisError ?? 'Unknown error')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Results')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(widget.imageFile, height: 200, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Text('Tooth: ${_scanResult!.toothName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Severity: ${_scanResult!.severity.toUpperCase()}', style: TextStyle(color: _severityColor, fontWeight: FontWeight.w600)),
            Text('Caries Percentage: ${_scanResult!.cariesPercentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            const Text('Issues Found:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._scanResult!.issues.map((issue) => Text('• $issue')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _shareResult,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateReport(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _severityColor {
    switch (_scanResult?.severity) {
      case 'severe': return Colors.red;
      case 'moderate': return Colors.orange;
      case 'mild': return Colors.yellow.shade800;
      default: return Colors.green;
    }
  }

  void _generateReport() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Generate Report'),
        content: Text('Report for ${_scanResult!.toothName}:\n\nSeverity: ${_scanResult!.severity}\nCaries: ${_scanResult!.cariesPercentage}%\nIssues:\n- ${_scanResult!.issues.join('\n- ')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Share.share('Dental Report:\n${_scanResult!.toothName}\n${_scanResult!.severity}\n${_scanResult!.cariesPercentage}%');
              Navigator.pop(context);
            },
            child: const Text('Share Report'),
          ),
        ],
      ),
    );
  }
}