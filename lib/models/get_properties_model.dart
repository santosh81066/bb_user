class Property {
  int? statusCode;
  bool? success;
  List<String>? messages;
  List<Data>? data;

  Property({this.statusCode, this.success, this.messages, this.data});

  Property.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    success = json['success'];
    messages = json['messages']?.cast<String>() ?? [];
    if (json['data'] != null) {
      data = List<Data>.from(json['data'].map((v) => Data.fromJson(v)));
    } else {
      data = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['success'] = success;
    data['messages'] = messages;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  Property copyWith({
    int? statusCode,
    bool? success,
    List<String>? messages,
    List<Data>? data,
  }) {
    return Property(
      statusCode: statusCode ?? this.statusCode,
      success: success ?? this.success,
      messages: messages ?? this.messages,
      data: data ?? this.data,
    );
  }

  static Property initial() {
    return Property(
      statusCode: 0,
      success: false,
      messages: [],
      data: [],
    );
  }
}

class Data {
  int? propertyId;
  String? propertyName;
  String? address;
  String? location;
  String? coverPic;
  int? category;
  List<Hall>? halls;

  Data({
    this.propertyId,
    this.propertyName,
    this.address,
    this.location,
    this.coverPic,
    this.category,
    this.halls,
  });

  Data.fromJson(Map<String, dynamic> json) {
    propertyId = json['property_id'];
    propertyName = json['propertyName'];
    address = json['address'];
    location = json['location'];
    coverPic = json['cover_pic'];
    category = json['category'];
    if (json['halls'] != null) {
      halls = List<Hall>.from(json['halls'].map((v) => Hall.fromJson(v)));
    } else {
      halls = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['property_id'] = propertyId;
    data['propertyName'] = propertyName;
    data['address'] = address;
    data['location'] = location;
    data['cover_pic'] = coverPic;
    data['category'] = category;
    if (halls != null) {
      data['halls'] = halls!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  Data copyWith({
    int? propertyId,
    String? propertyName,
    String? address,
    String? location,
    String? coverPic,
    int? category,
    List<Hall>? halls,
  }) {
    return Data(
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      address: address ?? this.address,
      location: location ?? this.location,
      coverPic: coverPic ?? this.coverPic,
      category: category ?? this.category,
      halls: halls ?? this.halls,
    );
  }

  static Data initial() {
    return Data(
      propertyId: 0,
      propertyName: "",
      address: "",
      location: "",
      coverPic: "",
      category: 0,
      halls: [],
    );
  }
}

class Hall {
  int? hallId;
  String? hallName; // Changed from 'name' to 'hallName'
  List<Slot>? slots; // Added slots list
  List<HallImage>? images; // Added images list

  Hall({this.hallId, this.hallName, this.slots, this.images});

  Hall.fromJson(Map<String, dynamic> json) {
    hallId = json['hall_id'];
    hallName = json['hall_name']; // Changed from 'Name' to 'hall_name'

    // Parse slots array
    if (json['slots'] != null) {
      slots = List<Slot>.from(json['slots'].map((v) => Slot.fromJson(v)));
    } else {
      slots = [];
    }

    // Parse images array
    if (json['images'] != null) {
      images = List<HallImage>.from(
          json['images'].map((v) => HallImage.fromJson(v)));
    } else {
      images = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hall_id'] = hallId;
    data['hall_name'] = hallName;
    if (slots != null) {
      data['slots'] = slots!.map((v) => v.toJson()).toList();
    }
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  Hall copyWith({
    int? hallId,
    String? hallName,
    List<Slot>? slots,
    List<HallImage>? images,
  }) {
    return Hall(
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      slots: slots ?? this.slots,
      images: images ?? this.images,
    );
  }

  static Hall initial() {
    return Hall(
      hallId: 0,
      hallName: "",
      slots: [],
      images: [],
    );
  }
}

// Add these additional classes for slots and images
class Slot {
  String? slotFromTime;
  String? slotToTime;

  Slot({this.slotFromTime, this.slotToTime});

  Slot.fromJson(Map<String, dynamic> json) {
    slotFromTime = json['slot_from_time'];
    slotToTime = json['slot_to_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['slot_from_time'] = slotFromTime;
    data['slot_to_time'] = slotToTime;
    return data;
  }
}

class HallImage {
  String? url;

  HallImage({this.url});

  HallImage.fromJson(Map<String, dynamic> json) {
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    return data;
  }
}
