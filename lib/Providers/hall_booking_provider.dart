import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/hall_booking.dart';
import '../models/authstate.dart';
import '../providers/auth.dart';

final hallBookingProvider =
    StateNotifierProvider<HallBookingNotifier, AsyncValue<void>>((ref) {
  return HallBookingNotifier(ref);
});

class HallBookingNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  HallBookingNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> postBooking({
    required int hallId,
    required String date,
    required String slotFromTime,
    required String slotToTime,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Get the auth state from the provider
      final authState = ref.read(authprovider);

      // Debug prints to verify auth state
      print("Auth state: ${authState.toJson()}");

      // Try to auto-login if no userId is found
      int? userId = authState.userId;
      if (userId == null) {
        // Attempt to refresh auth state with auto-login
        print("User ID is null, attempting to auto-login");
        final authNotifier = ref.read(authprovider.notifier);
        final autoLoginSuccess = await authNotifier.tryAutoLogin();
        print("Auto-login success: $autoLoginSuccess");

        // Get the updated auth state
        final updatedAuthState = ref.read(authprovider);
        userId = updatedAuthState.userId;
        print("Updated auth state userId: $userId");
      }

      // Check if userId exists after auto-login attempt
      if (userId == null) {
        throw Exception('User ID not found. Please log in again.');
      }

      // Create booking request
      final booking = HallBookingRequest(
        hallId: hallId,
        userId: userId,
        date: date,
        slotFromTime: slotFromTime,
        slotToTime: slotToTime,
      );

      // Print the request for debugging
      print("Booking request: ${booking.toJson()}");

      // Get token for authorization header
      final token = authState.token;
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      // Add authorization token if available
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('https://www.gocodedesigners.com/hallbooking'),
        headers: headers,
        body: jsonEncode(booking.toJson()),
      );

      // Print the response for debugging
      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print("Booking successful: ${responseData['messages']}");
        state = const AsyncValue.data(null);
      } else {
        try {
          final responseData = jsonDecode(response.body);
          final messages = responseData['messages'];
          throw Exception(messages is List
              ? messages.join(', ')
              : (messages ?? 'Booking failed'));
        } catch (decodeError) {
          throw Exception(
              'Booking failed with status code ${response.statusCode}');
        }
      }
    } catch (e, st) {
      print("Booking error: $e");
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
