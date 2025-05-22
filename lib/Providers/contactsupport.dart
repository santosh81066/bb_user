import 'dart:convert';
import 'package:bb_user/Providers/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final supportStateProvider = StateNotifierProvider<SupportStateNotifier, AsyncValue<void>>(
      (ref) => SupportStateNotifier(ref),
);

class SupportStateNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  SupportStateNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> submitSupportRequest({
    required String fullname,
    required String email,
    required String subject,
    required String message,
  }) async {
    const url = "http://www.gocodedesigners.com/bbusersupport";

    // Get the user ID from the auth provider
    final authState = ref.read(authprovider);
    final userId = authState.userId;

    // Check if user is authenticated
    if (userId == null) {
      state = AsyncValue.error("User not authenticated", StackTrace.current);
      return;
    }

    // Validate input data
    if (fullname.trim().isEmpty) {
      state = AsyncValue.error("Full name cannot be empty", StackTrace.current);
      return;
    }
    if (email.trim().isEmpty) {
      state = AsyncValue.error("Email cannot be empty", StackTrace.current);
      return;
    }
    if (subject.trim().isEmpty) {
      state = AsyncValue.error("Subject cannot be empty", StackTrace.current);
      return;
    }
    if (message.trim().isEmpty) {
      state = AsyncValue.error("Message cannot be empty", StackTrace.current);
      return;
    }

    final body = {
      "fullname": fullname.trim(),
      "email": email.trim(),
      "subject": subject.trim(),
      "message": message.trim(),
      "user_id": userId.toString(), // Ensure it's a string
    };

    try {
      state = const AsyncValue.loading();

      // Updated headers with proper formatting
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

      // Debug: Print the request details
      print("=== SUPPORT REQUEST DEBUG ===");
      print("URL: $url");
      print("Headers: $headers");
      print("Body: ${jsonEncode(body)}");
      print("User ID: $userId (Type: ${userId.runtimeType})");
      print("============================");

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print("=== RESPONSE DEBUG ===");
      print("Status Code: ${response.statusCode}");
      print("Response Headers: ${response.headers}");
      print("Response Body: ${response.body}");
      print("====================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Support request submitted successfully.");
        state = const AsyncValue.data(null);
      } else {
        // Try to parse error response
        String errorMessage = "Failed with status: ${response.statusCode}";

        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic>) {
            // Check for common error message fields
            if (responseData.containsKey('messages') && responseData['messages'] is List) {
              errorMessage = (responseData['messages'] as List).join(', ');
            } else if (responseData.containsKey('error')) {
              errorMessage = responseData['error'].toString();
            } else if (responseData.containsKey('message')) {
              errorMessage = responseData['message'].toString();
            }
          }
        } catch (e) {
          // If JSON parsing fails, use the raw response body
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }

        print("Failed to submit support request. Status: ${response.statusCode}");
        print("Error message: $errorMessage");
        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } catch (e, st) {
      print("Exception occurred: $e");
      print("Stack trace: $st");
      state = AsyncValue.error("Network error: ${e.toString()}", st);
    }
  }

  // Alternative method using form data if JSON continues to fail
  Future<void> submitSupportRequestFormData({
    required String fullname,
    required String email,
    required String subject,
    required String message,
  }) async {
    const url = "http://www.gocodedesigners.com/bbusersupport";

    // Get the user ID from the auth provider
    final authState = ref.read(authprovider);
    final userId = authState.userId;

    if (userId == null) {
      state = AsyncValue.error("User not authenticated", StackTrace.current);
      return;
    }

    try {
      state = const AsyncValue.loading();

      // Using MultipartRequest for form-data
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add form fields
      request.fields.addAll({
        'fullname': fullname.trim(),
        'email': email.trim(),
        'subject': subject.trim(),
        'message': message.trim(),
        'user_id': userId.toString(),
      });

      print("=== FORM DATA REQUEST DEBUG ===");
      print("URL: $url");
      print("Fields: ${request.fields}");
      print("================================");

      // Send request
      http.StreamedResponse streamedResponse = await request.send();
      http.Response response = await http.Response.fromStream(streamedResponse);

      print("=== FORM DATA RESPONSE DEBUG ===");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("===============================");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Support request submitted successfully via form data.");
        state = const AsyncValue.data(null);
      } else {
        String errorMessage = "Failed with status: ${response.statusCode}";
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic> && responseData.containsKey('messages')) {
            errorMessage = (responseData['messages'] as List).join(', ');
          }
        } catch (e) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } catch (e, st) {
      print("Exception occurred: $e");
      state = AsyncValue.error("Network error: ${e.toString()}", st);
    }
  }
}