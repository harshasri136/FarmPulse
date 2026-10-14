class FarmActivity {
  final int? id;
  final int? farmId;
  final int? cropId;

  final String title;
  final String type;
  final String description;

  final DateTime activityDate;

  final double expense;
  final double quantity;
  final String quantityUnit;

  final String notes;
  final DateTime createdAt;

  const FarmActivity({
    this.id,
    this.farmId,
    this.cropId,
    required this.title,
    this.type = 'Other',
    this.description = '',
    required this.activityDate,
    this.expense = 0,
    this.quantity = 0,
    this.quantityUnit = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'cropId': cropId,
      'title': title,
      'type': type,
      'description': description,
      'activityDate': activityDate.toIso8601String(),
      'expense': expense,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FarmActivity.fromMap(Map<String, dynamic> map) {
    return FarmActivity(
      id: map['id'] as int?,
      farmId: map['farmId'] as int?,
      cropId: map['cropId'] as int?,
      title: map['title'] as String,
      type: (map['type'] as String?) ?? 'Other',
      description: (map['description'] as String?) ?? '',
      activityDate: DateTime.parse(map['activityDate'] as String),
      expense: (map['expense'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      quantityUnit: (map['quantityUnit'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  FarmActivity copyWith({
    int? id,
    int? farmId,
    int? cropId,
    String? title,
    String? type,
    String? description,
    DateTime? activityDate,
    double? expense,
    double? quantity,
    String? quantityUnit,
    String? notes,
    DateTime? createdAt,
  }) {
    return FarmActivity(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      cropId: cropId ?? this.cropId,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      activityDate: activityDate ?? this.activityDate,
      expense: expense ?? this.expense,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
