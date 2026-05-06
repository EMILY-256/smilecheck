import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../widgets/scan_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scans = Provider.of<ScanProvider>(context).scans;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History'), automaticallyImplyLeading: false),
      body: scans.isEmpty
          ? const Center(child: Text('No scans yet. Start a new scan!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final scan = scans[index];
                return ScanCard(scan: scan, onTap: () => _showDetails(context, scan));
              },
            ),
    );
  }

  void _showDetails(BuildContext context, scan) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(scan.toothName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date: ${scan.date.toLocal()}'),
            Text('Severity: ${scan.severity}'),
            Text('Caries: ${scan.cariesPercentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            const Text('Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...scan.issues.map((i) => Text('• $i')),
          ],
        ),
      ),
    );
  }
}