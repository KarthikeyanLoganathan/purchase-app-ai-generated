// Helper function to safely parse int? values from maps
int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

class Material {
  final String uuid;
  final int? id;
  final String name;
  final String? description;
  final String unitOfMeasure;
  final String? website;
  final String? photoUuid;
  final DateTime updatedAt;

  Material({
    required this.uuid,
    this.id,
    required this.name,
    this.description,
    required this.unitOfMeasure,
    this.website,
    this.photoUuid,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'id': id,
      'name': name,
      'description': description,
      'unit_of_measure': unitOfMeasure,
      'website': website,
      'photo_uuid': photoUuid,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Material.fromMap(Map<String, dynamic> map) {
    return Material(
      uuid: map['uuid'] as String,
      id: _toIntNullable(map['id']),
      name: map['name'] as String,
      description: map['description'] as String?,
      unitOfMeasure: map['unit_of_measure'] as String,
      website: map['website'] as String?,
      photoUuid: map['photo_uuid'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Material copyWith({
    String? uuid,
    int? id,
    String? name,
    String? description,
    String? unitOfMeasure,
    String? website,
    String? photoUuid,
    DateTime? updatedAt,
  }) {
    return Material(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      website: website ?? this.website,
      photoUuid: photoUuid ?? this.photoUuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Material && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}
