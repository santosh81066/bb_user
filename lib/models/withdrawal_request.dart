class WithdrawalRequest {
  final String accountHolder;
  final double amount;
  final String? ifsc;
  final String? account;
  final String? upi;
  final int userId;
  final String status;

  const WithdrawalRequest({
    required this.accountHolder,
    required this.amount,
    this.ifsc,
    this.account,
    this.upi,
    required this.userId,
    this.status = 'p', // pending by default
  });

  Map<String, dynamic> toJson() {
    return {
      'account_holder': accountHolder,
      'amount': amount.toString(),
      if (ifsc != null) 'ifsc': ifsc,
      if (account != null) 'account': account,
      if (upi != null) 'upi': upi,
      'user_id': userId,
      'status': status,
    };
  }
}
