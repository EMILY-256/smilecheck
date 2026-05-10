import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_model.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../widgets/scan_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _refresh() async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    await Provider.of<ScanProvider>(context, listen: false)
        .loadScansForUser(userId);
  }

  Future<void> _confirmDelete(BuildContext context, Scan scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete scan?'),
        content: Text(
            'Remove the ${scan.toothName} scan from ${scan.date.toLocal().toString().split(' ').first}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final userId =
          Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
      await Provider.of<ScanProvider>(context, listen: false)
          .deleteScan(scan.id, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scans = Provider.of<ScanProvider>(context).scans;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Scan History'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: scans.isEmpty
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 300,
                  child: Center(child: Text('No scans yet. Start a new scan!')),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  return Dismissible(
                    key: Key(scan.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete scan?'),
                          content: Text(
                              'Remove the ${scan.toothName} scan from '
                              '${scan.date.toLocal().toString().split(' ').first}?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      return confirmed == true;
                    },
                    onDismissed: (_) async {
                      final userId =
                          Provider.of<AuthProvider>(context, listen: false)
                                  .user
                                  ?.id ??
                              '';
                      await Provider.of<ScanProvider>(context, listen: false)
                          .deleteScan(scan.id, userId);
                    },
                    child: ScanCard(
                        scan: scan, onTap: () => _showDetails(context, scan)),
                  );
                },
              ),
      ),
    );
  }

  void _showDetails(BuildContext context, Scan scan) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(scan.toothName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date: ${scan.date.toLocal()}'),
            Text('Result: ${_resultLabel(scan)}'),
            if (scan.severity != null) Text('Severity: ${scan.severity}'),
            Text('Confidence: ${scan.confidence.toStringAsFixed(1)}%'),
            if (scan.cariesPercentage != null && scan.resultType == 'caries')
              Text('Caries: ${scan.cariesPercentage!.toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            const Text('Issues:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...scan.issues.map((i) => Text('• $i')),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(context, scan);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  String _resultLabel(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return 'Image unsuitable';
      case 'caries':
        return 'Possible caries';
      default:
        return 'Healthy';
    }
  }
}
