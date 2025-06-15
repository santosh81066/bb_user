// hall_booking_provider.dart - Enhanced Version with Better isPaid Status Handling
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

      // Get all existing bookings for this slot
      final getResponse = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
      );

      if (getResponse.statusCode != 200) {
        throw Exception('Failed to fetch existing bookings');
      }

      final bookings = jsonDecode(getResponse.body)['data'] as List;
      int? existingBookingId;
      bool slotAlreadyConfirmed = false;

      // Check for existing bookings in this slot
      for (var booking in bookings) {
        if (booking['hall_id'] == hallId &&
            booking['date'] == date &&
            booking['slot_from_time'] == slotFromTime &&
            booking['slot_to_time'] == slotToTime) {
          // Check if any user has already confirmed this slot
          if (booking['is_paid'] == 'y') {
            slotAlreadyConfirmed = true;
            break;
          }

          // Check if current user has existing booking for this slot
          if (booking['user_id'] == userId) {
            existingBookingId = booking['id'];
          }
        }
      }

      // Prevent booking if slot is already confirmed by someone else
      if (slotAlreadyConfirmed) {
        throw Exception('This slot has already been confirmed by another user');
      }

      // If current user has existing booking or bookingId is provided, update it
      if (existingBookingId != null || bookingId != null) {
        await updateBookingPaymentStatus(
          bookingId: existingBookingId ?? bookingId!,
          status: isPaid,
        );
        return;
      }

      // Create new booking
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
        throw Exception(messages is List
            ? messages.join(', ')
            : (messages ?? 'Booking failed'));
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

      final url = Uri.parse(Bbapi.hallbooking);

      final patchResponse = await http.patch(
        url,
        headers: headers,
        body: patchBody,
      );

      if (patchResponse.statusCode == 200) {
        state = const AsyncValue.data(null);
      } else {
        final responseData = jsonDecode(patchResponse.body);
        final errorMessage = responseData['message'] ??
            'Failed to update booking payment status';
        throw Exception(errorMessage);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Enhanced method to update isPaid status with better error handling
  Future<bool> updateBookingIsPaidStatus({
    required int bookingId,
    required bool isPaid,
    String? paymentId,
    String? paymentMethod,
  }) async {
    try {
      final authState = ref.read(authprovider);
      final token = authState.token;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final requestBody = {
        "booking_id": bookingId,
        "is_paid": isPaid ? 'y' : 'n',
        "updated_at": DateTime.now().toIso8601String(),
      };

      // Add payment details if provided
      if (paymentId != null) {
        requestBody["payment_id"] = paymentId;
      }
      if (paymentMethod != null) {
        requestBody["payment_method"] = paymentMethod;
      }

      final response = await http.patch(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update isPaid status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating isPaid status: $e');
      return false;
    }
  }

  // Method to cancel a booking
  Future<bool> cancelBooking({
    required int bookingId,
  }) async {
    state = const AsyncValue.loading();

    try {
      await updateBookingPaymentStatus(
        bookingId: bookingId,
        status: 'cl', // Using 'cl' for cancelled status
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print("Error cancelling booking: $e");
      return false;
    }
  }

  // Enhanced method to handle both wallet and razorpay payments
  Future<bool> updateBookingWithPayment({
    required int hallId,
    required int? bookingId,
    required String date,
    required String slotFromTime,
    required String slotToTime,
    required String paymentMethod,
    required String paymentId,
    required double amount,
    required bool isSuccess,
  }) async {
    state = const AsyncValue.loading();

    try {
      print('Starting payment update process...');
      print(
          'BookingId: $bookingId, IsSuccess: $isSuccess, PaymentMethod: $paymentMethod');

      // First, ensure we have a booking (create or update)
      int finalBookingId;

      if (bookingId != null) {
        // Update existing booking
        finalBookingId = bookingId;
        print('Using existing booking ID: $finalBookingId');
      } else {
        // Create new booking first with 'b' status (blocked/pending)
        await postBooking(
          hallId: hallId,
          bookingId: null,
          date: date,
          slotFromTime: slotFromTime,
          slotToTime: slotToTime,
          isPaid: 'b', // Initially set as blocked/pending
        );

        // Get the newly created booking ID
        finalBookingId = await _getBookingId(
          hallId: hallId,
          date: date,
          slotFromTime: slotFromTime,
          slotToTime: slotToTime,
        );
        print('Created new booking with ID: $finalBookingId');
      }

      // Now update the payment status based on success/failure
      String paymentStatus;
      if (isSuccess) {
        paymentStatus = 'y'; // paid/confirmed
        print('Payment successful - updating status to: $paymentStatus');
      } else {
        paymentStatus = 'n'; // failed
        print('Payment failed - updating status to: $paymentStatus');
      }

      // Update the booking with the final payment status
      bool statusUpdateSuccess = await updateBookingIsPaidStatus(
        bookingId: finalBookingId,
        isPaid: isSuccess,
        paymentId: paymentId,
        paymentMethod: paymentMethod,
      );

      if (!statusUpdateSuccess) {
        // Fallback: use the original method
        print('Fallback: Using original update method');
        await updateBookingPaymentStatus(
          bookingId: finalBookingId,
          status: paymentStatus,
        );
      }

      // Double-check: For successful payments, ensure status is 'y'
      if (isSuccess) {
        await updateBookingPaymentStatus(
          bookingId: finalBookingId,
          status: 'y',
        );
        print('Final confirmation: Payment status set to "y" (paid)');
      }

      state = const AsyncValue.data(null);
      print('Payment update process completed successfully');
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print("Error updating booking with payment: $e");
      print("Stack trace: $st");

      // On error, try to mark booking as failed if we have a booking ID
      if (bookingId != null) {
        try {
          await updateBookingPaymentStatus(
            bookingId: bookingId,
            status: 'n', // failed
          );
          print('Marked booking as failed due to error');
        } catch (fallbackError) {
          print('Failed to mark booking as failed: $fallbackError');
        }
      }

      return false;
    }
  }

  // Helper method to get a booking ID by hall and time details
  Future<int> _getBookingId({
    required int hallId,
    required String date,
    required String slotFromTime,
    required String slotToTime,
  }) async {
    try {
      final authState = ref.read(authprovider);
      int? userId = authState.userId;
      final token = authState.token;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch bookings');
      }

      final bookings = jsonDecode(response.body)['data'] as List;

      for (var booking in bookings) {
        if (booking['user_id'] == userId &&
            booking['hall_id'] == hallId &&
            booking['date'] == date &&
            booking['slot_from_time'] == slotFromTime &&
            booking['slot_to_time'] == slotToTime) {
          return booking['id'];
        }
      }

      throw Exception('Booking not found');
    } catch (e) {
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
        final HallBookingResponse bookingResponse =
            HallBookingResponse.fromJson(responseData);
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

    final response =
        await http.get(Uri.parse(Bbapi.hallbooking), headers: headers);

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
