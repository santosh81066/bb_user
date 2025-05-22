// ignore_for_file: unused_import

import 'dart:convert';
import 'package:bb_user/Providers/venues_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/get_hall_booking.dart';
import '../models/get_properties_model.dart';
import '../providers/auth.dart';
import '../utils/bbapi.dart';

// Create a class to manage the hall booking state
class GetHallBookingNotifier
    extends StateNotifier<AsyncValue<List<GetHallBooking>>> {
  final Ref ref;

  GetHallBookingNotifier(this.ref) : super(const AsyncValue.loading());

  // Explicit method to load bookings
  Future<void> loadBookings() async {
    // Set loading state
    state = const AsyncValue.loading();

    try {
      // Get the auth state from the provider
      final authState = ref.read(authprovider);

      // Debug prints to verify auth state
      print("Auth state: ${authState.toJson()}");

      // Try to auto-login if no userId is found
      int? userId = authState.userId;
      String? token = authState.token;

      if (userId == null) {
        // Attempt to refresh auth state with auto-login
        print("User ID is null, attempting to auto-login");
        final authNotifier = ref.read(authprovider.notifier);
        final autoLoginSuccess = await authNotifier.tryAutoLogin();
        print("Auto-login success: $autoLoginSuccess");

        // Get the updated auth state after auto-login
        final updatedAuthState = ref.read(authprovider);
        userId = updatedAuthState.userId;
        token = updatedAuthState.token;
        print("Updated auth state userId: $userId");
      }

      // Check if userId and token exist after auto-login attempt
      if (userId == null || token == null) {
        throw Exception('User authentication failed. Please log in again.');
      }

      // Get booking data
      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final bookingsData = responseData['data'] as List<dynamic>;
          print('Decoded hall booking response: $responseData');

          // Always filter bookings for the current user (no fallback to show all)
          final userBookings = bookingsData
              .map((booking) => GetHallBooking.fromJson(booking))
              .where((booking) => booking.userId == userId)
              .toList();

          print('Filtered bookings count: ${userBookings.length}');

          // Get properties data
          final propertyState = ref.read(propertyNotifierProvider);
          final propertiesData = propertyState.data;

          // Populate hall names and property names
          if (propertiesData != null) {
            for (var booking in userBookings) {
              for (var property in propertiesData) {
                if (property.halls != null) {
                  for (var hall in property.halls!) {
                    if (hall.hallId == booking.hallId) {
                      booking.hallName = hall.name;
                      booking.propertyName = property.propertyName;
                      break;
                    }
                  }
                }
                if (booking.hallName != null) break; // Stop if found
              }
            }
          }

          // Update state with filtered data
          state = AsyncValue.data(userBookings);
        } else {
          state =
              AsyncValue.error('Invalid response format', StackTrace.current);
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized access
        state = AsyncValue.error(
            'Authentication failed. Please log in again.', StackTrace.current);
      } else {
        state = AsyncValue.error(
            'Failed to load bookings: ${response.statusCode}',
            StackTrace.current);
      }
    } catch (error, stackTrace) {
      print('Error loading bookings: $error');
      state = AsyncValue.error('Error: $error', stackTrace);
    }
  }

  // Method to refresh bookings
  Future<void> refresh() async {
    await loadBookings();
  }
}

// Create a StateNotifierProvider for the hall bookings
final gethallBookingsNotifierProvider = StateNotifierProvider<
    GetHallBookingNotifier, AsyncValue<List<GetHallBooking>>>((ref) {
  return GetHallBookingNotifier(ref);
});
