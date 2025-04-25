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

      // // Check if auth data exists
      // if (authState.data == null) {
      //   print("Auth data is null!");
      //   throw Exception("User not logged in. Authentication data is missing.");
      // }
      //
      // // Get user ID and print for debugging
      // final userId = authState.data!.userId;
      // print("Retrieved userId: $userId");
      //
      // if (userId == null || userId == 0) {
      //   print("User ID is null or zero!");
      //   throw Exception("User ID is missing or invalid.");
      // }
      final int userId = 43;
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

      final response = await http.post(
        Uri.parse('https://www.gocodedesigners.com/hallbooking'),
        headers: {
          'Content-Type': 'application/json',
        },
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
          throw Exception(
              messages is List ? messages.join(', ') : 'Booking failed');
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
