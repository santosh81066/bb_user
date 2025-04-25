class HallBookingRequest {
  final int hallId;
  final int userId;
  final String date;
  final String slotFromTime;
  final String slotToTime;

  HallBookingRequest({
    required this.hallId,
    required this.userId,
    required this.date,
    required this.slotFromTime,
    required this.slotToTime,
  });

  Map<String, dynamic> toJson() => {
        "hall_id": hallId,
        "user_id": userId,
        "date": date,
        "slot_from_time": slotFromTime,
        "slot_to_time": slotToTime,
      };
}
