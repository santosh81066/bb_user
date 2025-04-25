// lib/models/property_model.dart
class PropertyModel {
  final int propertyId;
  final String propertyName;
  final String address;
  final String coverPic;

  PropertyModel({
    required this.propertyId,
    required this.propertyName,
    required this.address,
    required this.coverPic,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      propertyId: json['property_id'],
      propertyName: json['propertyName'],
      address: json['address'],
      coverPic: json['cover_pic'],
    );
  }
}
