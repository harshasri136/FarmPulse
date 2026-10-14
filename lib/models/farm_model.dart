class FarmModel {
  final int? id;
  final String name;
  final String location;
  final double area;
  final String areaUnit;
  final String soilType;
  final String description;
  final DateTime createdAt;

  const FarmModel({
    this.id,
    required this.name,
    required this.location,
    required this.area,
    this.areaUnit = 'Acres',
    this.soilType = 'Loamy',
    this.description = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'area': area,
      'areaUnit': areaUnit,
      'soilType': soilType,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FarmModel.fromMap(Map<String, dynamic> map) {
    return FarmModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String,
      area: (map['area'] as num).toDouble(),
      areaUnit: map['areaUnit'] as String? ?? 'Acres',
      soilType: map['soilType'] as String? ?? 'Loamy',
      description: map['description'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  FarmModel copyWith({
    int? id,
    String? name,
    String? location,
    double? area,
    String? areaUnit,
    String? soilType,
    String? description,
    DateTime? createdAt,
  }) {
    return FarmModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      soilType: soilType ?? this.soilType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
