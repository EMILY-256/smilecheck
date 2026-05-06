import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scan_model.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../widgets/scan_card.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScanProvider>(context, listen: false).loadScans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final scanProvider = Provider.of<ScanProvider>(context);
    final scans = scanProvider.scans;
    final totalScans = scans.length;
    final issuesFound = scans.where((s) => s.severity != 'healthy').length;
    final lastScan = scans.isNotEmpty ? scans.first.date : null;
    final healthScore = _calculateHealthScore(scans);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home tab content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Good morning + name
                Text(
                  'Good morning, ${auth.user?.name ?? "User"}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let’s check your dental health',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                // Dental Health Score Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Dental Health Score',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${healthScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          healthScore >= 70
                              ? 'Good'
                              : (healthScore >= 40
                                  ? 'Needs attention'
                                  : 'Critical'),
                          style: TextStyle(
                            color: healthScore >= 70
                                ? Colors.green
                                : (healthScore >= 40
                                    ? Colors.orange
                                    : Colors.red),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('$totalScans', 'Total Scans'),
                            _buildStat('$issuesFound', 'Issues Found'),
                            _buildStat(
                                lastScan != null
                                    ? '${lastScan.day}/${lastScan.month}/${lastScan.year}'
                                    : '--',
                                'Last Scan'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // New Dental Scan button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ScanScreen())),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('New Dental Scan',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 24),
                // Recent Scans header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Scans',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                // List of recent scans (max 3)
                ...scans.take(3).map((scan) => ScanCard(
                      scan: scan,
                      onTap: () => _showScanDetails(scan),
                    )),
                if (scans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child: Text('No scans yet. Start with a new scan!')),
                  ),
              ],
            ),
          ),
          // History tab
          HistoryScreen(),
          // Profile tab
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  double _calculateHealthScore(List<Scan> scans) {
    if (scans.isEmpty) return 100;
    double totalCaries = 0;
    for (var scan in scans) {
      if (scan.severity == 'severe')
        totalCaries += 80;
      else if (scan.severity == 'moderate')
        totalCaries += 50;
      else if (scan.severity == 'mild')
        totalCaries += 20;
      else
        totalCaries += 5;
    }
    double avgCaries = totalCaries / scans.length;
    double health = 100 - avgCaries;
    return health.clamp(0, 100);
  }

  void _showScanDetails(Scan scan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(scan.toothName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date: ${scan.date.toLocal()}'),
            Text('Severity: ${scan.severity.toUpperCase()}'),
            Text('Caries %: ${scan.cariesPercentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            const Text('Issues:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...scan.issues.map((i) => Text('• $i')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _shareScan(scan),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _generateReport(scan),
                  icon: const Icon(Icons.description),
                  label: const Text('Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareScan(Scan scan) async {
    // Use share_plus
    await Future.delayed(Duration.zero);
    // Implementation in share_plus will be added in analysis screen
  }

  void _generateReport(Scan scan) {
    // Navigate to report screen or show PDF – simplified
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report Generated'),
        content:
            Text('Report for ${scan.toothName}:\n${scan.issues.join(', ')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }
}
