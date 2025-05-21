class GetHallBooking {
  final int id;
  final int hallId;
  final int userId;
  final String date;
  final String slotFromTime;
  final String slotToTime;
  final String isPaid;
  String? hallName;
  String? propertyName;

  GetHallBooking({
    required this.id,
    required this.hallId,
    required this.userId,
    required this.date,
    required this.slotFromTime,
    required this.slotToTime,
    required this.isPaid,
    this.hallName,
    this.propertyName,
  });

  // Add the copyWith method
  GetHallBooking copyWith({
    int? id,
    int? hallId,
    int? userId,
    String? date,
    String? slotFromTime,
    String? slotToTime,
    String? isPaid,
    String? hallName,
    String? propertyName,
  }) {
    return GetHallBooking(
      id: id ?? this.id,
      hallId: hallId ?? this.hallId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      slotFromTime: slotFromTime ?? this.slotFromTime,
      slotToTime: slotToTime ?? this.slotToTime,
      isPaid: isPaid ?? this.isPaid,
      hallName: hallName ?? this.hallName,
      propertyName: propertyName ?? this.propertyName,
    );
  }

  factory GetHallBooking.fromJson(Map<String, dynamic> json) {
    return GetHallBooking(
      id: json['id'],
      hallId: json['hall_id'],
      userId: json['user_id'],
      date: json['date'] ?? '',
      slotFromTime: _sanitizeTime(json['slot_from_time']),  // Fixed typo here
      slotToTime: _sanitizeTime(json['slot_to_time']),      // Fixed typo here
      isPaid: json['is_paid']?.toString() ?? '',
      hallName: json['hall_name'],
      propertyName: json['property_name'],
    );
  }

  static String _sanitizeTime(dynamic time) {
    if (time == null || time.toString().isEmpty || !time.toString().contains(':')) {
      return '00:00';
    }
    return time.toString();
  }
}