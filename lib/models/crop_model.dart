class CropModel {
  final int? id;
  final int farmId;
  final String name;
  final String variety;
  final DateTime plantingDate;
  final DateTime harvestDate;
  final String growthStage;
  final String status;
  final String notes;
  final DateTime createdAt;

  const CropModel({
    this.id,
    required this.farmId,
    required this.name,
    this.variety = '',
    required this.plantingDate,
    required this.harvestDate,
    this.growthStage = 'Seedling',
    this.status = 'Growing',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'name': name,
      'variety': variety,
      'plantingDate': plantingDate.toIso8601String(),
      'harvestDate': harvestDate.toIso8601String(),
      'growthStage': growthStage,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CropModel.fromMap(Map<String, dynamic> map) {
    return CropModel(
      id: map['id'] as int?,
      farmId: map['farmId'] as int,
      name: map['name'] as String? ?? '',
      variety: map['variety'] as String? ?? '',
      plantingDate: DateTime.parse(map['plantingDate'] as String),
      harvestDate: DateTime.parse(map['harvestDate'] as String),
      growthStage: map['growthStage'] as String? ?? 'Seedling',
      status: map['status'] as String? ?? 'Growing',
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  CropModel copyWith({
    int? id,
    int? farmId,
    String? name,
    String? variety,
    DateTime? plantingDate,
    DateTime? harvestDate,
    String? growthStage,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return CropModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      growthStage: growthStage ?? this.growthStage,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
