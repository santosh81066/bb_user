import 'dart:convert';
import 'package:bb_user/Providers/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

final supportStateProvider =
    StateNotifierProvider<SupportStateNotifier, AsyncValue<void>>(
  (ref) => SupportStateNotifier(ref),
);

class SupportStateNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  late Dio dio = Dio();

  SupportStateNotifier(this.ref) : super(const AsyncValue.data(null)) {
    // Initialize Dio with similar settings to Postman
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'User-Agent': 'PostmanRuntime/7.43.4',
        'Cache-Control': 'no-cache',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      },
    ));

    // Add logging interceptor
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
    ));
  }

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
      "user_id": userId.toString(),
    };

    try {
      state = const AsyncValue.loading();

      print("=== DIO REQUEST ATTEMPT ===");
      print("URL: $url");
      print("Body: $body");

      // Try with Dio
      final response = await dio.post(
        url,
        data: body, // Dio automatically converts to JSON
      );

      print("=== DIO RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response Data: ${response.data}");
      print("Response Headers: ${response.headers}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Support request submitted successfully with Dio!");
        state = const AsyncValue.data(null);
      } else {
        String errorMessage = "Failed with status: ${response.statusCode}";

        if (response.data != null) {
          try {
            final responseData = response.data;
            if (responseData is Map<String, dynamic>) {
              if (responseData.containsKey('messages') &&
                  responseData['messages'] is List) {
                errorMessage = (responseData['messages'] as List).join(', ');
              } else if (responseData.containsKey('error')) {
                errorMessage = responseData['error'].toString();
              } else if (responseData.containsKey('message')) {
                errorMessage = responseData['message'].toString();
              }
            }
          } catch (e) {
            errorMessage = response.data.toString();
          }
        }

        print(
            "Failed to submit support request. Status: ${response.statusCode}");
        print("Error message: $errorMessage");
        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } on DioException catch (e) {
      print("=== DIO EXCEPTION ===");
      print("Error Type: ${e.type}");
      print("Error Message: ${e.message}");
      print("Response: ${e.response?.data}");
      print("Status Code: ${e.response?.statusCode}");

      String errorMessage = "Network error";

      if (e.response != null) {
        try {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('messages')) {
            errorMessage = (responseData['messages'] as List).join(', ');
          } else {
            errorMessage = "Server error: ${e.response!.statusCode}";
          }
        } catch (parseError) {
          errorMessage = "Server error: ${e.response!.statusCode}";
        }
      } else {
        errorMessage = e.message ?? "Network connection failed";
      }

      state = AsyncValue.error(errorMessage, StackTrace.current);
    } catch (e, st) {
      print("=== GENERAL EXCEPTION ===");
      print("Exception: $e");
      print("Stack trace: $st");
      state = AsyncValue.error("Unexpected error: ${e.toString()}", st);
    }
  }
}
