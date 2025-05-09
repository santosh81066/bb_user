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
    required int id,
    required int hallId,
    required String date,
    required String slotFromTime,
    required String slotToTime,
    required bool isBlocked,
    required bool isPaid,
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

      // ✅ Use your real endpoint: GET all bookings
      final getResponse = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
      );

      if (getResponse.statusCode != 200) {
        throw Exception('Failed to check existing bookings');
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

      final bookingStatus = isPaid
          ? BookingStatus.confirmed
          : (isBlocked ? BookingStatus.blocked : BookingStatus.available);

      if (existingBookingId != null) {
        await updateBookingPaymentStatus(
          bookingId: existingBookingId,
          status: bookingStatus,
        );
        return;
      }

      // ➕ No existing booking → POST new
      final booking = HallBookingRequest(
        id: id,
        hallId: hallId,
        userId: userId,
        date: date,
        slotFromTime: slotFromTime,
        slotToTime: slotToTime,
        isPaid: bookingStatusToCode(bookingStatus),
      );

      final postResponse = await http.post(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
        body: jsonEncode(booking.toJson()),
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
    required BookingStatus status,
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
        "is_paid": bookingStatusToCode(status),
      });

      final patchResponse = await http.patch(
        Uri.parse(Bbapi.hallbooking),
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



  // ✅ New Method: Count blocked & confirmed slots by hall ID
  Future<Map<String, int>> countSlotStatuses(int hallId) async {
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

      int blockedCount = 0;
      int confirmedCount = 0;

      for (var messageList in messages) {
        for (var booking in messageList) {
          final status = booking['is_paid'];
          if (status == 'b') blockedCount++;
          if (status == 'c') confirmedCount++;
        }
      }

      return {
        'blocked': blockedCount,
        'confirmed': confirmedCount,
      };
    } else {
      throw Exception('Failed to fetch slot status counts');
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

}