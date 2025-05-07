class HallBookingRequest {
  final int id;
  final int hallId;
  final int userId;
  final String date;
  final String slotFromTime;
  final String slotToTime;
  final int isBlocked;
  final int isPaid;

  HallBookingRequest({
    required this.id,
    required this.hallId,
    required this.userId,
    required this.date,
    required this.slotFromTime,
    required this.slotToTime,
    required this.isBlocked,
    required this.isPaid,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "hall_id": hallId,
    "user_id": userId,
    "date": date,
    "slot_from_time": slotFromTime,
    "slot_to_time": slotToTime,
    "is_blocked": isBlocked,
    "is_paid": isPaid,
  };
}