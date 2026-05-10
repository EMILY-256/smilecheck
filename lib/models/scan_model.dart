class Scan {
  final String id;
  final String userId;
  final String imagePath;
  final DateTime date;
  final String toothName; // e.g., "Lower Right Molars"
  final String resultType; // "caries", "healthy", "unsuitable"
  final String? severity; // "mild", "moderate", "severe"
  final double confidence; // 0-100
  final double?
      cariesPercentage; // 0-100 when diagnosis model returns caries probability
  final String modelLabel;
  final String stage1Label;
  final double stage1Confidence; // 0-100
  final String? stage2Label;
  final double? stage2Confidence; // 0-100
  final List<String> issues; // e.g., ["Enamel decay", "Dentin involvement"]

  Scan({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.date,
    required this.toothName,
    required this.resultType,
    this.severity,
    required this.confidence,
    this.cariesPercentage,
    required this.modelLabel,
    required this.stage1Label,
    required this.stage1Confidence,
    this.stage2Label,
    this.stage2Confidence,
    required this.issues,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'imagePath': imagePath,
        'date': date.toIso8601String(),
        'toothName': toothName,
        'resultType': resultType,
        'severity': severity,
        'confidence': confidence,
        'cariesPercentage': cariesPercentage,
        'modelLabel': modelLabel,
        'stage1Label': stage1Label,
        'stage1Confidence': stage1Confidence,
        'stage2Label': stage2Label,
        'stage2Confidence': stage2Confidence,
        'issues': issues,
      };

  factory Scan.fromJson(Map<String, dynamic> json) => Scan(
        id: json['id'],
        userId: json['userId'],
        imagePath: json['imagePath'],
        date: DateTime.parse(json['date']),
        toothName: json['toothName'],
        resultType: json['resultType'],
        severity: json['severity'],
        confidence: (json['confidence'] as num).toDouble(),
        cariesPercentage: (json['cariesPercentage'] as num?)?.toDouble(),
        modelLabel: json['modelLabel'],
        stage1Label: json['stage1Label'],
        stage1Confidence: (json['stage1Confidence'] as num).toDouble(),
        stage2Label: json['stage2Label'],
        stage2Confidence: (json['stage2Confidence'] as num?)?.toDouble(),
        issues: List<String>.from(json['issues']),
      );
}
