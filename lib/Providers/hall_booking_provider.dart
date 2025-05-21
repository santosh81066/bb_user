// ==================== PROVIDER: hall_booking_provider.dart ====================
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/hall_booking.dart';
import '../providers/auth.dart';
import '../utils/bbapi.dart';

final hallBookingProvider =
StateNotifierProvider<HallBookingNotifier, AsyncValue<void>>((ref) {
  return HallBookingNotifier(ref);
});

class HallBookingNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  HallBookingNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> postBooking({
    required int hallId,
    required int? bookingId,
    required String date,
    required String slotFromTime,
    required String slotToTime,
    required String isPaid,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authprovider);
      int? userId = authState.userId;

      if (userId == null) {
        final authNotifier = ref.read(authprovider.notifier);
        await authNotifier.tryAutoLogin();
        userId = ref.read(authprovider).userId;
        if (userId == null) throw Exception('User ID not found.');
      }

      final token = authState.token;
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Check if this user already blocked/confirmed this slot
      final getResponse = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
      );

      if (getResponse.statusCode != 200) {
        throw Exception('Failed to fetch existing bookings');
      }

      final bookings = jsonDecode(getResponse.body)['data'] as List;
      int? existingBookingId;

      for (var booking in bookings) {
        if (booking['user_id'] == userId &&
            booking['hall_id'] == hallId &&
            booking['date'] == date &&
            booking['slot_from_time'] == slotFromTime &&
            booking['slot_to_time'] == slotToTime) {
          existingBookingId = booking['id'];
          break;
        }
      }

      if (existingBookingId != null || bookingId != null) {
        await updateBookingPaymentStatus(
          bookingId: existingBookingId ?? bookingId!,
          status: isPaid,
        );
        return;
      }

      final requestBody = {
        "hall_id": hallId,
        "user_id": userId,
        "date": date,
        "slot_from_time": slotFromTime,
        "slot_to_time": slotToTime,
        "is_paid": isPaid,
      };

      final postResponse = await http.post(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
        state = const AsyncValue.data(null);
      } else {
        final responseData = jsonDecode(postResponse.body);
        final messages = responseData['messages'];
        throw Exception(messages is List ? messages.join(', ') : (messages ?? 'Booking failed'));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  Future<void> updateBookingPaymentStatus({
    required int bookingId,
    required String status,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authprovider);
      final token = authState.token;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final patchBody = jsonEncode({
        "booking_id": bookingId,
        "is_paid": status,
      });

      final url = Uri.parse(Bbapi.hallbooking); // <-- Fixed: do NOT append bookingId

      final patchResponse = await http.patch(
        url,
        headers: headers,
        body: patchBody,
      );


      if (patchResponse.statusCode == 200) {
        state = const AsyncValue.data(null);
      } else {
        throw Exception('Failed to update booking payment status');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }



  Future<List<HallBookingData>> getBookings() async {
    try {
      final authState = ref.read(authprovider);
      final token = authState.token;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final HallBookingResponse bookingResponse = HallBookingResponse.fromJson(responseData);
        return bookingResponse.data;
      } else {
        throw Exception('Failed to fetch bookings');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }
  Future<int> countUniqueBlockedUsersPerDay(int hallId) async {
    final authState = ref.read(authprovider);
    final headers = {
      'Authorization': 'Bearer ${authState.token}',
      'Content-Type': 'application/json',
    };

    final response = await http.get(
      Uri.parse(Bbapi.hallbooking),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final messages = jsonResponse['messages'] as List;

      final Set<String> uniqueUserDateCombos = {};

      for (var messageList in messages) {
        for (var booking in messageList) {
          final userId = booking['user_id'];
          final date = booking['date'];
          final status = booking['is_paid'];

          if (status == 'b' && userId != null && date != null) {
            uniqueUserDateCombos.add('$userId-$date');
          }
        }
      }

      return uniqueUserDateCombos.length;
    } else {
      throw Exception('Failed to count unique blocked users');
    }
  }
  Future<int> countUsersBlockedSameSlot({
    required int hallId,
    required String date,
    required String fromTime,
    required String toTime,
  }) async {
    final authState = ref.read(authprovider);
    final headers = {
      'Authorization': 'Bearer ${authState.token}',
      'Content-Type': 'application/json',
    };

    final response = await http.get(Uri.parse(Bbapi.hallbooking), headers: headers);

    if (response.statusCode != 200) throw Exception('Failed to load bookings');

    final responseData = jsonDecode(response.body);
    final List bookings = responseData['data'];

    final filtered = bookings.where((booking) =>
    booking['hall_id'] == hallId &&
        booking['date'] == date &&
        booking['slot_from_time'] == fromTime &&
        booking['slot_to_time'] == toTime &&
        booking['is_paid'] == 'b' // blocked
    );

    final uniqueUserIds = filtered.map((b) => b['user_id']).toSet();
    return uniqueUserIds.length;
  }

}

// Next: The booking screen and calendar logic will follow
