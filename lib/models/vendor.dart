import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/base/model_definition.dart';

abstract class VendorFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const name = 'name';
  static const description = 'description';
  static const address = 'address';
  static const geoLocation = 'geoLocation';
  static const phoneNumber = 'phoneNumber';
  static const emailAddress = 'emailAddress';
  static const website = 'website';
  static const photoUuid = 'photoUuid';
  static const updatedAt = 'updatedAt';
}

abstract class VendorTableFields {
  static const uuid = 'uuid';
  static const id = 'id';
  static const name = 'name';
  static const description = 'description';
  static const address = 'address';
  static const geoLocation = 'geo_location';
  static const phoneNumber = 'phone_number';
  static const emailAddress = 'email_address';
  static const website = 'website';
  static const photoUuid = 'photo_uuid';
  static const updatedAt = 'updated_at';
}

class Vendor {
  final String uuid;
  final int? id;
  final String name;
  final String? description;
  final String? address;
  final String? geoLocation;
  final String? phoneNumber;
  final String? emailAddress;
  final String? website;
  final String? photoUuid;
  final DateTime updatedAt;

  Vendor({
    required this.uuid,
    this.id,
    required this.name,
    this.description,
    this.address,
    this.geoLocation,
    this.phoneNumber,
    this.emailAddress,
    this.website,
    this.photoUuid,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      VendorTableFields.uuid: uuid,
      VendorTableFields.id: id,
      VendorTableFields.name: name,
      VendorTableFields.description: description,
      VendorTableFields.address: address,
      VendorTableFields.geoLocation: geoLocation,
      VendorTableFields.phoneNumber: phoneNumber,
      VendorTableFields.emailAddress: emailAddress,
      VendorTableFields.website: website,
      VendorTableFields.photoUuid: photoUuid,
      VendorTableFields.updatedAt: updatedAt,
    };
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      uuid: map[VendorTableFields.uuid],
      id: map[VendorTableFields.id],
      name: map[VendorTableFields.name],
      description: map[VendorTableFields.description],
      address: map[VendorTableFields.address],
      geoLocation: map[VendorTableFields.geoLocation],
      phoneNumber: map[VendorTableFields.phoneNumber],
      emailAddress: map[VendorTableFields.emailAddress],
      website: map[VendorTableFields.website],
      photoUuid: map[VendorTableFields.photoUuid],
      updatedAt: map[VendorTableFields.updatedAt],
    );
  }

  Vendor copyWith({
    String? uuid,
    int? id,
    String? name,
    String? description,
    String? address,
    String? geoLocation,
    String? phoneNumber,
    String? emailAddress,
    String? website,
    String? photoUuid,
    DateTime? updatedAt,
  }) {
    return Vendor(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      geoLocation: geoLocation ?? this.geoLocation,
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
    return other is Vendor && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;

  static final _uuidFieldDef = ModelFieldDefinition(
      name: VendorFields.uuid,
      tableFieldName: VendorTableFields.uuid,
      isPrimaryKey: true,
      isNullable: false,
      isUnique: true,
      type: String);

  static final _idFieldDef = ModelFieldDefinition(
      name: VendorFields.id,
      tableFieldName: VendorTableFields.id,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: int);

  static final _nameFieldDef = ModelFieldDefinition(
      name: VendorFields.name,
      tableFieldName: VendorTableFields.name,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: String);

  static final _descriptionFieldDef = ModelFieldDefinition(
      name: VendorFields.description,
      tableFieldName: VendorTableFields.description,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _addressFieldDef = ModelFieldDefinition(
      name: VendorFields.address,
      tableFieldName: VendorTableFields.address,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _geoLocationFieldDef = ModelFieldDefinition(
      name: VendorFields.geoLocation,
      tableFieldName: VendorTableFields.geoLocation,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _phoneNumberFieldDef = ModelFieldDefinition(
      name: VendorFields.phoneNumber,
      tableFieldName: VendorTableFields.phoneNumber,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _emailAddressFieldDef = ModelFieldDefinition(
      name: VendorFields.emailAddress,
      tableFieldName: VendorTableFields.emailAddress,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _websiteFieldDef = ModelFieldDefinition(
      name: VendorFields.website,
      tableFieldName: VendorTableFields.website,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _photoUuidFieldDef = ModelFieldDefinition(
      name: VendorFields.photoUuid,
      tableFieldName: VendorTableFields.photoUuid,
      isPrimaryKey: false,
      isNullable: true,
      isUnique: false,
      type: String);

  static final _updatedAtFieldDef = ModelFieldDefinition(
      name: VendorFields.updatedAt,
      tableFieldName: VendorTableFields.updatedAt,
      isPrimaryKey: false,
      isNullable: false,
      isUnique: false,
      type: DateTime);

  static final modelDefinition = ModelDefinition(
      name: 'Vendor',
      databaseTableName: TableNames.vendors,
      type: ModelTypes.masterData,
      displayName: 'Vendor',
      tableIndex: 202,
      fromMap: Vendor.fromMap,
      toMap: (dynamic instance) => (instance as Vendor).toMap(),
      fields: {
        VendorFields.uuid: _uuidFieldDef,
        VendorFields.id: _idFieldDef,
        VendorFields.name: _nameFieldDef,
        VendorFields.description: _descriptionFieldDef,
        VendorFields.address: _addressFieldDef,
        VendorFields.geoLocation: _geoLocationFieldDef,
        VendorFields.phoneNumber: _phoneNumberFieldDef,
        VendorFields.emailAddress: _emailAddressFieldDef,
        VendorFields.website: _websiteFieldDef,
        VendorFields.photoUuid: _photoUuidFieldDef,
        VendorFields.updatedAt: _updatedAtFieldDef,
      });

  Map<String, dynamic> toDbMap() {
    return modelDefinition.toDbMap(this);
  }

  factory Vendor.fromDbMap(Map<String, dynamic> map) {
    return modelDefinition.fromDbMap(map) as Vendor;
  }
}
