import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';
import 'package:uuid/uuid.dart';

abstract class ProjectFields {
  static const uuid = 'uuid';
  static const name = 'name';
  static const description = 'description';
  static const address = 'address';
  static const phoneNumber = 'phoneNumber';
  static const geoLocation = 'geoLocation';
  static const startDate = 'startDate';
  static const endDate = 'endDate';
  static const completed = 'completed';
  static const updatedAt = 'updatedAt';
}

abstract class ProjectTableFields {
  static const uuid = 'uuid';
  static const name = 'name';
  static const description = 'description';
  static const address = 'address';
  static const phoneNumber = 'phone_number';
  static const geoLocation = 'geo_location';
  static const startDate = 'start_date';
  static const endDate = 'end_date';
  static const completed = 'completed';
  static const updatedAt = 'updated_at';
}

class Project {
  final String uuid;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? geoLocation;
  final DateTime? startDate;
  final DateTime? endDate;
  final int completed;
  final DateTime updatedAt;

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
    DateTime? updatedAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      ProjectTableFields.uuid: uuid,
      ProjectTableFields.name: name,
      ProjectTableFields.description: description,
      ProjectTableFields.address: address,
      ProjectTableFields.phoneNumber: phoneNumber,
      ProjectTableFields.geoLocation: geoLocation,
      ProjectTableFields.startDate: startDate,
      ProjectTableFields.endDate: endDate,
      ProjectTableFields.completed: completed,
      ProjectTableFields.updatedAt: updatedAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      uuid: map[ProjectTableFields.uuid],
      name: map[ProjectTableFields.name],
      description: map[ProjectTableFields.description],
      address: map[ProjectTableFields.address],
      phoneNumber: map[ProjectTableFields.phoneNumber],
      geoLocation: map[ProjectTableFields.geoLocation],
      startDate: map[ProjectTableFields.startDate],
      endDate: map[ProjectTableFields.endDate],
      completed: map[ProjectTableFields.completed],
      updatedAt: map[ProjectTableFields.updatedAt],
    );
  }

  Project copyWith({
    String? uuid,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? geoLocation,
    DateTime? startDate,
    DateTime? endDate,
    int? completed,
    DateTime? updatedAt,
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

  static final _uuidFieldDef = ModelFieldDefinition(
      name: ProjectFields.uuid,
      tableFieldName: ProjectTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _nameFieldDef = ModelFieldDefinition(
      name: ProjectFields.name,
      tableFieldName: ProjectTableFields.name,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: ProjectFields.description,
      tableFieldName: ProjectTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _addressFieldDef = ModelFieldDefinition(
      name: ProjectFields.address,
      tableFieldName: ProjectTableFields.address,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _phoneNumberFieldDef = ModelFieldDefinition(
      name: ProjectFields.phoneNumber,
      tableFieldName: ProjectTableFields.phoneNumber,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _geoLocationFieldDef = ModelFieldDefinition(
      name: ProjectFields.geoLocation,
      tableFieldName: ProjectTableFields.geoLocation,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _startDateFieldDef = ModelFieldDefinition(
      name: ProjectFields.startDate,
      tableFieldName: ProjectTableFields.startDate,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: DateTime);

  static final _endDateFieldDef = ModelFieldDefinition(
      name: ProjectFields.endDate,
      tableFieldName: ProjectTableFields.endDate,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: DateTime);

  static final _completedFieldDef = ModelFieldDefinition(
      name: ProjectFields.completed,
      tableFieldName: ProjectTableFields.completed,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: int);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: ProjectFields.updatedAt,
      tableFieldName: ProjectTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Project',
      databaseTableName: TableNames.projects,
      type: ModelTypes.transactionData,
      displayName: 'Project',
      tableIndex: 251,
      fromMap: Project.fromMap,
      toMap: (dynamic instance) => (instance as Project).toMap(),
      fields: {
        ProjectFields.uuid: _uuidFieldDef,
        ProjectFields.name: _nameFieldDef,
        ProjectFields.description: _descriptionFieldDef,
        ProjectFields.address: _addressFieldDef,
        ProjectFields.phoneNumber: _phoneNumberFieldDef,
        ProjectFields.geoLocation: _geoLocationFieldDef,
        ProjectFields.startDate: _startDateFieldDef,
        ProjectFields.endDate: _endDateFieldDef,
        ProjectFields.completed: _completedFieldDef,
        ProjectFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Project.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Project;
  }
}
