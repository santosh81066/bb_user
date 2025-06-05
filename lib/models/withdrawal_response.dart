// File: lib/models/withdrawal_response.dart
class WithdrawalResponse {
  final int statusCode;
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  const WithdrawalResponse({
    required this.statusCode,
    required this.success,
    this.message,
    this.data,
  });

  factory WithdrawalResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalResponse(
      statusCode: json['statusCode'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }
}