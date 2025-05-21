// Model class for support request
class SupportRequest {
  final String fullname;
  final String email;
  final String subject;
  final String message;
  final int userId;

  SupportRequest({
    required this.fullname,
    required this.email,
    required this.subject,
    required this.message,
    required this.userId,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'fullname': fullname,
      'email': email,
      'subject': subject,
      'message': message,
      'user_id': userId,
    };
  }
}
