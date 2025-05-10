class Transaction {
  final int id;
  final int userId;
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
  final int amount;

  Transaction({
    required this.id,
    required this.userId,
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
    required this.amount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      razorpayOrderId: json['razorpay_order_id'],
      razorpaySignature: json['razorpay_signature'],
      amount: json['amt'],
    );
  }
}
