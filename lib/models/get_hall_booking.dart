class GetHallBooking {
  final int id;
  final int hallId;
  final int userId;
  final String date;
  final String slotFromTime;
  final String slotToTime;
  final int isBlocked;
  final int isPaid;
  String? hallName;
  String? propertyName;

  GetHallBooking({
    required this.id,
    required this.hallId,
    required this.userId,
    required this.date,
    required this.slotFromTime,
    required this.slotToTime,
    required this.isBlocked,
    required this.isPaid,
    this.hallName,
    this.propertyName,
  });

  factory GetHallBooking.fromJson(Map<String, dynamic> json) {
    return GetHallBooking(
      id: json['id'],
      hallId: json['hall_id'],
      userId: json['user_id'],
      date: json['date'],
      slotFromTime: json['slot_from_time'],
      slotToTime: json['slot_to_time'],
      isBlocked: json['is_blocked'],
      isPaid: json['is_paid'],
    );
  }
}
