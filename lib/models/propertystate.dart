class Propertystate {
  final int? id;
  final String? propertyPic;
  final String? address1;
  final String? address2;
  final int? reviewCount;
  final int? averageRating;
  final String? location;
  final String? state;
  final String? city;
  final String? pincode;
  final String? activationStatus;

  Propertystate({
    this.id,
    this.propertyPic,
    this.address1,
    this.address2,
    this.reviewCount,
    this.averageRating,
    this.location,
    this.state,
    this.city,
    this.pincode,
    this.activationStatus,
  });

  Propertystate.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        propertyPic = json['property_pic'] as String?,
        address1 = json['address_1'] as String?,
        address2 = json['address_2'] as String?,
        reviewCount = json['review_count'] as int?,
        averageRating = json['average_rating'] as int?,
        location = json['location'] as String?,
        state = json['state'] as String?,
        city = json['city'] as String?,
        pincode = json['pincode'] as String?,
        activationStatus = json['activation_status'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_pic': propertyPic,
        'address_1': address1,
        'address_2': address2,
        'review_count': reviewCount,
        'average_rating': averageRating,
        'location': location,
        'state': state,
        'city': city,
        'pincode': pincode,
        'activation_status': activationStatus,
      };

  Propertystate copyWith({
    int? id,
    String? propertyPic,
    String? address1,
    String? address2,
    int? reviewCount,
    int? averageRating,
    String? location,
    String? state,
    String? city,
    String? pincode,
    String? activationStatus,
  }) {
    return Propertystate(
      id: id ?? this.id,
      propertyPic: propertyPic ?? this.propertyPic,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      reviewCount: reviewCount ?? this.reviewCount,
      averageRating: averageRating ?? this.averageRating,
      location: location ?? this.location,
      state: state ?? this.state,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      activationStatus: activationStatus ?? this.activationStatus,
    );
  }

  Propertystate clear() {
    return Propertystate(
      id: null,
      propertyPic: null,
      address1: null,
      address2: null,
      reviewCount: null,
      averageRating: null,
      location: null,
      state: null,
      city: null,
      pincode: null,
      activationStatus: null,
    );
  }
}
