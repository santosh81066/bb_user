class Subscription {
  final int subscriptionId;
  final String propertyName;
  final String hallName;
  final String subscriptionPlan;
  final String mainPlan;
  final int status;
  final DateTime startTime;
  final DateTime expiry;
  final int Id;

  Subscription({
    required this.subscriptionId,
    required this.propertyName,
    required this.hallName,
    required this.subscriptionPlan,
    required this.mainPlan,
    required this.status,
    required this.startTime,
    required this.expiry,
    required this.Id,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      subscriptionId: json['subscription_id'],
      propertyName: json['property_name'],
      hallName: json['hall_name'],
      subscriptionPlan: json['subscription_plan'],
      mainPlan: json['main_plan'],
      status: json['status'],
      startTime: DateTime.parse(json['start_time']),
      expiry: DateTime.parse(json['expiry']),
      Id: json['property_id'],
    );
  }
}
