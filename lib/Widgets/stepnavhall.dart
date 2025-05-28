/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bb_user/models/get_properties_model.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/auth.dart';
import '../Providers/hall_booking_provider.dart';
import 'package:intl/intl.dart';
import '../Widgets/buildhallfeatures.dart';
import '../Widgets/hall_selection.dart';
import '../models/hall_booking.dart';
import '../utils/bbapi.dart';

class Stepnavhall extends StatefulWidget {
  const Stepnavhall({super.key});

  @override
  State<Stepnavhall> createState() => _StepnavhallState();
}

class _StepnavhallState extends State<Stepnavhall> {
  int currentStep = 0, selectedHallIndex = 0;
  late AnimationController _animationController;
  DateTime? selectedDay;
  String? selectedSlot;
  late  Ref ref;
  String _getBookingKey(int hallId, String date, String fromTime, String toTime) =>
      '$hallId-$date-$fromTime-$toTime';
  Map<String, BookingStatus> bookingStatuses = {};
  BookingStatus _mapStatusCode(String code) => switch (code) {
    'c' => BookingStatus.confirmed,
    'b' => BookingStatus.blocked,
    _ => BookingStatus.available,
  };




  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _animationController.reset();
      _animationController.forward();
    }
  }
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handlePaymentSuccess(Hall hall, String date, String fromTime, String toTime) async {
    final bookingKey = _getBookingKey(hall.hallId ?? 0, date, fromTime, toTime);

    try {

      final authState = ref.read(authprovider);
      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) throw Exception("Failed to retrieve booking data");

      final List bookings = jsonDecode(response.body)['data'];
      int? bookingId;

      for (var booking in bookings) {
        if (booking['hall_id'] == hall.hallId &&
            booking['user_id'] == authState.userId &&
            booking['date'] == date &&
            booking['slot_from_time'] == fromTime &&
            booking['slot_to_time'] == toTime &&
            booking['is_paid'] == bookingStatusToString(BookingStatus.blocked)) {
          bookingId = booking['id'];
          break;
        }
      }

      if (bookingId == null) throw Exception("Booking not found for payment update.");

      await ref.read(hallBookingProvider.notifier).updateBookingPaymentStatus(
        bookingId: bookingId,
        status: bookingStatusToString(BookingStatus.confirmed),
      );

      setState(() => bookingStatuses[bookingKey] = BookingStatus.confirmed);

      if (context.mounted) _showDialog();
      _loadExistingBookings();
    } catch (e) {
      if (context.mounted) _showSnackBar('Payment update failed: ${e.toString()}', isError: true);
    }
  }
  void _loadExistingBookings() async {
    try {
      final authState = ref.read(authprovider);
      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: {
          'Authorization': 'Bearer ${authState.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List bookings = jsonDecode(response.body)['data'];
        final updatedStatuses = <String, BookingStatus>{};

        for (var booking in bookings) {
          final key = _getBookingKey(booking['hall_id'], booking['date'],
              booking['slot_from_time'], booking['slot_to_time']);
          updatedStatuses[key] = _mapStatusCode(booking['is_paid']);
        }

        if (mounted) setState(() => bookingStatuses = updatedStatuses);
      }
    } catch (e) {
      debugPrint("Error loading bookings: $e");
    }
  }
  void _showDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Booking Confirmed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Your hall has been successfully booked.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  void _goToPayment() {
    final args = ModalRoute.of(context)?.settings.arguments as Map;
    final Data property = args['property'];
    final hall = property.halls![selectedHallIndex];

    if (selectedDay == null || selectedSlot == null) return;

    final slotParts = selectedSlot!.split('From: ')[1].split(' To: ');
    final formattedDate = "${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}";

    Navigator.pushNamed(context, '/payment', arguments: {
      'hallId': hall.hallId,
      'date': formattedDate,
      'slotFromTime': slotParts[0],
      'slotToTime': slotParts[1],
      'hallName': hall.name,
      'price': hall.price,
      'onPaymentSuccess': (bool success) {
        if (success) _handlePaymentSuccess(hall, formattedDate, slotParts[0], slotParts[1]);
      },
    });
  }

  void _handleNextButton() {
    if (currentStep == 2 && selectedDay == null) {
      _showSnackBar('Please select a date');
      return;
    }
    if (currentStep == 3 && selectedSlot == null) {
      _showSnackBar ('Please select a time slot');
      return;
    }
    if (currentStep == 3) {
      _goToPayment();
    } else {
      _nextStep();
    }
  }

  void _nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
      _animationController.reset();
      _animationController.forward();
    }
  }


  @override
  Widget build(BuildContext context) {
    int currentStep = 0, selectedHallIndex = 0;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleNextButton(),
              icon: Icon(currentStep == 3 ? Icons.payment : Icons.arrow_forward),
              label: Text(currentStep == 3 ? 'Proceed to Payment' : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
