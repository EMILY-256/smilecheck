import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_model.dart';

class ScanCard extends StatelessWidget {
  final Scan scan;
  final VoidCallback? onTap;

  const ScanCard({Key? key, required this.scan, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    switch (scan.severity) {
      case 'severe':
        severityColor = Colors.red;
        break;
      case 'moderate':
        severityColor = Colors.orange;
        break;
      case 'mild':
        severityColor = Colors.yellow;
        break;
      default:
        severityColor = Colors.green;
    }

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
                            color: severityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${scan.severity.toUpperCase()} - ${scan.cariesPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: severityColor,
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
}
