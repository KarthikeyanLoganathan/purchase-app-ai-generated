import 'package:uuid/uuid.dart';

class Project {
  final String uuid;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? geoLocation;
  final String? startDate;
  final String? endDate;
  final int completed;
  final String updatedAt;

  Project({
    String? uuid,
    required this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.geoLocation,
    this.startDate,
    this.endDate,
    this.completed = 0,
    String? updatedAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'address': address,
      'phone_number': phoneNumber,
      'geo_location': geoLocation,
      'start_date': startDate,
      'end_date': endDate,
      'completed': completed,
      'updated_at': updatedAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      address: map['address'] as String?,
      phoneNumber: map['phone_number'] as String?,
      geoLocation: map['geo_location'] as String?,
      startDate: map['start_date'] as String?,
      endDate: map['end_date'] as String?,
      completed: map['completed'] as int? ?? 0,
      updatedAt: map['updated_at'] as String,
    );
  }

  Project copyWith({
    String? uuid,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? geoLocation,
    String? startDate,
    String? endDate,
    int? completed,
    String? updatedAt,
  }) {
    return Project(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      geoLocation: geoLocation ?? this.geoLocation,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Project{uuid: $uuid, name: $name, description: $description, '
        'address: $address, phoneNumber: $phoneNumber, geoLocation: $geoLocation, '
        'startDate: $startDate, endDate: $endDate, completed: $completed, updatedAt: $updatedAt}';
  }
}
