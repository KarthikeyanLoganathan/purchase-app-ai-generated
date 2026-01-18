import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class ManufacturerFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const name = 'name';
  static const description = 'description';
  static const address = 'address';
  static const phoneNumber = 'phoneNumber';
  static const emailAddress = 'emailAddress';
  static const website = 'website';
  static const photoUuid = 'photoUuid';
  static const updatedAt = 'updatedAt';
}

abstract class ManufacturerTableFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const name = 'name';
  static const description = 'description';
  static const address = 'address';
  static const phoneNumber = 'phone_number';
  static const emailAddress = 'email_address';
  static const website = 'website';
  static const photoUuid = 'photo_uuid';
  static const updatedAt = 'updated_at';
}

class Manufacturer {
  final String uuid;
  final int? id;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final String? emailAddress;
  final String? website;
  final String? photoUuid;
  final DateTime updatedAt;

  Manufacturer({
    required this.uuid,
    this.id,
    required this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.emailAddress,
    this.website,
    this.photoUuid,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      ManufacturerTableFields.uuid: uuid,
      ManufacturerTableFields.id: id,
      ManufacturerTableFields.name: name,
      ManufacturerTableFields.description: description,
      ManufacturerTableFields.address: address,
      ManufacturerTableFields.phoneNumber: phoneNumber,
      ManufacturerTableFields.emailAddress: emailAddress,
      ManufacturerTableFields.website: website,
      ManufacturerTableFields.photoUuid: photoUuid,
      ManufacturerTableFields.updatedAt: updatedAt,
    };
  }

  factory Manufacturer.fromMap(Map<String, dynamic> map) {
    return Manufacturer(
      uuid: map[ManufacturerTableFields.uuid],
      id: map[ManufacturerTableFields.id],
      name: map[ManufacturerTableFields.name],
      description: map[ManufacturerTableFields.description],
      address: map[ManufacturerTableFields.address],
      phoneNumber: map[ManufacturerTableFields.phoneNumber],
      emailAddress: map[ManufacturerTableFields.emailAddress],
      website: map[ManufacturerTableFields.website],
      photoUuid: map[ManufacturerTableFields.photoUuid],
      updatedAt: map[ManufacturerTableFields.updatedAt],
    );
  }

  Manufacturer copyWith({
    String? uuid,
    int? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? emailAddress,
    String? website,
    String? photoUuid,
    DateTime? updatedAt,
  }) {
    return Manufacturer(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      website: website ?? this.website,
      photoUuid: photoUuid ?? this.photoUuid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manufacturer && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;

  static final _uuidFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.uuid,
      tableFieldName: ManufacturerTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.id,
      tableFieldName: ManufacturerTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _nameFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.name,
      tableFieldName: ManufacturerTableFields.name,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.description,
      tableFieldName: ManufacturerTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _addressFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.address,
      tableFieldName: ManufacturerTableFields.address,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _phoneNumberFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.phoneNumber,
      tableFieldName: ManufacturerTableFields.phoneNumber,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _emailAddressFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.emailAddress,
      tableFieldName: ManufacturerTableFields.emailAddress,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _websiteFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.website,
      tableFieldName: ManufacturerTableFields.website,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _photoUuidFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.photoUuid,
      tableFieldName: ManufacturerTableFields.photoUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: ManufacturerFields.updatedAt,
      tableFieldName: ManufacturerTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Manufacturer',
      databaseTableName: TableNames.manufacturers,
      type: ModelTypes.masterData,
      displayName: 'Manufacturer',
      tableIndex: 201,
      fromMap: Manufacturer.fromMap,
      toMap: (dynamic instance) => (instance as Manufacturer).toMap(),
      fields: {
        ManufacturerFields.uuid: _uuidFieldDef,
        ManufacturerFields.id: _idFieldDef,
        ManufacturerFields.name: _nameFieldDef,
        ManufacturerFields.description: _descriptionFieldDef,
        ManufacturerFields.address: _addressFieldDef,
        ManufacturerFields.phoneNumber: _phoneNumberFieldDef,
        ManufacturerFields.emailAddress: _emailAddressFieldDef,
        ManufacturerFields.website: _websiteFieldDef,
        ManufacturerFields.photoUuid: _photoUuidFieldDef,
        ManufacturerFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Manufacturer.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Manufacturer;
  }
}
