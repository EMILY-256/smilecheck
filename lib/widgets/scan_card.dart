import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_model.dart';

class ScanCard extends StatelessWidget {
  final Scan scan;
  final VoidCallback? onTap;

  const ScanCard({Key? key, required this.scan, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(scan);
    final statusText = _statusText(scan);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(scan.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.toothName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${scan.date.day}/${scan.date.month}/${scan.date.year}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return Colors.blueGrey;
      case 'caries':
        switch (scan.severity) {
          case 'severe':
            return Colors.red;
          case 'moderate':
            return Colors.orange;
          default:
            return Colors.amber;
        }
      default:
        return Colors.green;
    }
  }

  String _statusText(Scan scan) {
    switch (scan.resultType) {
      case 'unsuitable':
        return 'UNSUITABLE - ${scan.confidence.toStringAsFixed(1)}%';
      case 'caries':
        return '${(scan.severity ?? 'caries').toUpperCase()} - ${scan.confidence.toStringAsFixed(1)}%';
      default:
        return 'HEALTHY - ${scan.confidence.toStringAsFixed(1)}%';
    }
  }
}
