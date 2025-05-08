// hall_booking.dart
enum BookingStatus {
  available,  // maps to "0"
  blocked,    // maps to "b"
  confirmed,  // maps to "c"
}

BookingStatus bookingStatusFromCode(String code) {
  switch (code) {
    case 'b':
      return BookingStatus.blocked;
    case 'c':
      return BookingStatus.confirmed;
    case '0':
    default:
      return BookingStatus.available;
  }
}

String bookingStatusToCode(BookingStatus status) {
  switch (status) {
    case BookingStatus.blocked:
      return 'b';
    case BookingStatus.confirmed:
      return 'c';
    case BookingStatus.available:
    default:
      return '0';
  }
}

String bookingStatusToString(BookingStatus status) => status.name;

class HallBookingRequest {
  final int id;
  final int hallId;
  final int userId;
  final String date;
  final String slotFromTime;
  final String slotToTime;
  final String isPaid;
  // new field

  HallBookingRequest({
    required this.id,
    required this.hallId,
    required this.userId,
    required this.date,
    required this.slotFromTime,
    required this.slotToTime,
    required this.isPaid,

  });

  factory HallBookingRequest.fromJson(Map<String, dynamic> json) {
    return HallBookingRequest(
      id: json['id'],
      hallId: json['hall_id'],
      userId: json['user_id'],
      date: json['date'],
      slotFromTime: json['slot_from_time'],
      slotToTime: json['slot_to_time'],
      isPaid: json['is_paid'],

    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "hall_id": hallId,
    "user_id": userId,
    "date": date,
    "slot_from_time": slotFromTime,
    "slot_to_time": slotToTime,
    "is_paid": isPaid,

  };
}


// Response model
class HallBookingResponse {
  final int statusCode;
  final bool success;
  final List<List<HallBookingData>> messages;
  final dynamic data;

  HallBookingResponse({
    required this.statusCode,
    required this.success,
    required this.messages,
    this.data,
  });

  factory HallBookingResponse.fromJson(Map<String, dynamic> json) {
    List<List<HallBookingData>> messagesData = [];

    if (json['messages'] is List) {
      messagesData = (json['messages'] as List).map((outerList) {
        if (outerList is List) {
          return (outerList as List).map((item) {
            return HallBookingData.fromJson(item as Map<String, dynamic>);
          }).toList();
        }
        return <HallBookingData>[];
      }).toList();
    }

    return HallBookingResponse(
      statusCode: json['statusCode'],
      success: json['success'],
      messages: messagesData,
      data: json['data'],
    );
  }
}

class HallBookingData {
  final int id;
  final int hallId;
  final int userId;
  final String date;
  final String slotFromTime;
  final String slotToTime;
  final String isPaid;
  final BookingStatus bookingStatus;

  HallBookingData({
    required this.id,
    required this.hallId,
    required this.userId,
    required this.date,
    required this.slotFromTime,
    required this.slotToTime,
    required this.isPaid,
    required this.bookingStatus,
  });

  factory HallBookingData.fromJson(Map<String, dynamic> json) {
    return HallBookingData(
      id: json['id'],
      hallId: json['hall_id'],
      userId: json['user_id'],
      date: json['date'],
      slotFromTime: json['slot_from_time'],
      slotToTime: json['slot_to_time'],
      isPaid: json['is_paid'],
      bookingStatus: bookingStatusFromCode(json['is_paid']),
    );
  }
}

