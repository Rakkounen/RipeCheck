class FruitPredictionModel {
  final String id;
  final String userId;
  final String fruitName;
  final String ripenessStatus;
  final double confidence;
  final String imagePath;
  final DateTime createdAt;

  FruitPredictionModel({
    required this.id,
    this.userId = '',
    required this.fruitName,
    required this.ripenessStatus,
    required this.confidence,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fruitName': fruitName,
      'ripenessStatus': ripenessStatus,
      'confidence': confidence,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FruitPredictionModel.fromMap(Map<String, dynamic> map) {
    return FruitPredictionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fruitName: map['fruitName'] ?? '',
      ripenessStatus: map['ripenessStatus'] ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: map['imagePath'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
