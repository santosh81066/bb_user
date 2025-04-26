import 'dart:convert';
import 'package:bb_user/Providers/venues_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/get_hall_booking.dart';
import '../models/get_properties_model.dart';
import '../providers/auth.dart';

final hallBookingsProvider =
    FutureProvider.autoDispose<List<GetHallBooking>>((ref) async {
  // Get the auth state
  final authState = ref.read(authprovider);
  final userId = authState.userId;

  // Get booking data
  final response = await http.get(
    Uri.parse('https://www.gocodedesigners.com/hallbooking'),
    headers: {
      'Content-Type': 'application/json',
      if (authState.token != null) 'Authorization': 'Bearer ${authState.token}',
    },
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    if (responseData['success'] == true && responseData['messages'] != null) {
      // Extract bookings from the response
      final bookingsData = responseData['messages'][0] as List<dynamic>;

      // Filter bookings for the current user
      final userBookings = bookingsData
          .map((booking) => GetHallBooking.fromJson(booking))
          .where((booking) => booking.userId == userId)
          .toList();

      // Get properties data using your existing provider
      final propertyState = ref.read(propertyNotifierProvider);
      final propertiesData = propertyState.data;

      // Populate hall names and property names
      if (propertiesData != null) {
        for (var booking in userBookings) {
          for (var property in propertiesData) {
            if (property.halls != null) {
              for (var hall in property.halls!) {
                if (hall.hallId == booking.hallId) {
                  booking.hallName = hall.hallName;
                  booking.propertyName = property.propertyName;
                  break;
                }
              }
            }
            if (booking.hallName != null) break; // Stop if found
          }
        }
      }

      return userBookings;
    }
  }

  throw Exception('Failed to load bookings');
});
