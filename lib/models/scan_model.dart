class Scan {
  final String id;
  final String imagePath;
  final DateTime date;
  final String toothName; // e.g., "Lower Right Molars"
  final String severity; // "mild", "moderate", "severe", "healthy"
  final double cariesPercentage; // 0-100
  final List<String> issues; // e.g., ["Enamel decay", "Dentin involvement"]

  Scan({
    required this.id,
    required this.imagePath,
    required this.date,
    required this.toothName,
    required this.severity,
    required this.cariesPercentage,
    required this.issues,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'date': date.toIso8601String(),
        'toothName': toothName,
        'severity': severity,
        'cariesPercentage': cariesPercentage,
        'issues': issues,
      };

  factory Scan.fromJson(Map<String, dynamic> json) => Scan(
        id: json['id'],
        imagePath: json['imagePath'],
        date: DateTime.parse(json['date']),
        toothName: json['toothName'],
        severity: json['severity'],
        cariesPercentage: json['cariesPercentage'],
        issues: List<String>.from(json['issues']),
      );
}