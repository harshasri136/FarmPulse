class FarmReminder {
  final int? id;
  final int? farmId;
  final int? cropId;
  final String title;
  final String description;
  final String type;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  const FarmReminder({
    this.id,
    this.farmId,
    this.cropId,
    required this.title,
    this.description = '',
    this.type = 'General',
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'cropId': cropId,
      'title': title,
      'description': description,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FarmReminder.fromMap(Map<String, dynamic> map) {
    return FarmReminder(
      id: map['id'] as int?,
      farmId: map['farmId'] as int?,
      cropId: map['cropId'] as int?,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'General',
      dueDate: DateTime.parse(map['dueDate'] as String),
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  FarmReminder copyWith({
    int? id,
    int? farmId,
    int? cropId,
    String? title,
    String? description,
    String? type,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return FarmReminder(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      cropId: cropId ?? this.cropId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
