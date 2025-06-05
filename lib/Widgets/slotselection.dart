import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/get_properties_model.dart';
import '../models/hall_booking.dart';

class Slotselection extends StatefulWidget {
  final Hall hall;
  final DateTime? selectedDay;
  final String? selectedSlot;
  final Function(String) onSlotSelected;
  final Map<String, BookingStatus> bookingStatuses;
  final Map<String, int> bookingUserIds; // Add this to track user IDs for blocked slots
  final int? currentUserId; // Add current user ID

  const Slotselection({
    super.key,
    required this.hall,
    this.selectedDay,
    this.selectedSlot,
    required this.onSlotSelected,
    required this.bookingStatuses,
    required this.bookingUserIds,
    required this.currentUserId,
  });

  @override
  State<Slotselection> createState() => _SlotselectionState();
}

class _SlotselectionState extends State<Slotselection> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  DateTime _parseTime(String timeStr, DateTime baseDate) {
    final parsedTime = DateFormat.Hms().parse(timeStr);
    return DateTime(baseDate.year, baseDate.month, baseDate.day,
        parsedTime.hour, parsedTime.minute);
  }

  String _getBookingKey(int hallId, String date, String fromTime, String toTime) =>
      '$hallId-$date-$fromTime-$toTime';

  @override
  Widget build(BuildContext context) {
    if (widget.selectedDay == null) {
      return _buildEmpty('Please select a date first', Icons.date_range);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader('Choose Time Slot', Icons.access_time),
          const SizedBox(height: 20),
          _buildDateSummary(),
          const SizedBox(height: 20),
          _buildTimeSlots(),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message, IconData icon) => Container(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(icon, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        Text(message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildHeader(String title, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600]),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        _iconContainer(icon, Colors.white.withOpacity(0.2)),
        const SizedBox(width: 15),
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  Widget _buildDateSummary() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400]),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        const Icon(Icons.event, color: Colors.white, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking for', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDay!),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTimeSlots() {
    final slots = widget.hall.slots;
    if (slots?.isEmpty ?? true) {
      return _buildEmpty('No time slots available', Icons.schedule_outlined);
    }

    final now = DateTime.now();
    final isToday = widget.selectedDay!.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDay!);

    return Column(
      children: slots!.map((slot) {
        final slotDisplay = 'From: ${slot.slotFromTime ?? ''} To: ${slot.slotToTime ?? ''}';
        final slotFromTime = _parseTime(slot.slotFromTime ?? '', widget.selectedDay!);
        final bookingKey = _getBookingKey(widget.hall.hallId ?? 0, formattedDate,
            slot.slotFromTime ?? '', slot.slotToTime ?? '');
        final bookingStatus = widget.bookingStatuses[bookingKey];
        final bookingUserId = widget.bookingUserIds[bookingKey];

        final isDisabled = (isToday && slotFromTime.isBefore(now)) ||
            bookingStatus == BookingStatus.confirmed;
        final isSelected = widget.selectedSlot == slotDisplay;

        // Check if slot is blocked by current user
        final isBlockedByCurrentUser = bookingStatus == BookingStatus.blocked &&
            bookingUserId != null &&
            widget.currentUserId != null &&
            bookingUserId == widget.currentUserId;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildTimeSlotCard(slotDisplay, bookingStatus, isDisabled, isSelected, isBlockedByCurrentUser),
        );
      }).toList(),
    );
  }

  Widget _iconContainer(IconData icon, [Color? backgroundColor]) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: backgroundColor ?? Colors.deepPurple.shade100,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: backgroundColor != null ? Colors.white : Colors.deepPurple, size: 24),
  );

  Widget _buildTimeSlotCard(String slotDisplay, BookingStatus? bookingStatus, bool isDisabled, bool isSelected, bool isBlockedByCurrentUser) {
    final (cardColor, textColor, statusIcon) = _getSlotCardColors(isDisabled, isSelected, bookingStatus, isBlockedByCurrentUser);

    return GestureDetector(
      onTap: isDisabled ? null : () => widget.onSlotSelected(slotDisplay),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.deepPurple : Colors.transparent, width: 2),
          boxShadow: isSelected ? [
            BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: isSelected ? Colors.white : textColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slotDisplay, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(_getSlotStatusMessage(bookingStatus, isDisabled, isBlockedByCurrentUser),
                      style: TextStyle(color: isSelected ? Colors.white70 : textColor.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('SELECTED',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _getSlotCardColors(bool isDisabled, bool isSelected, BookingStatus? status, bool isBlockedByCurrentUser) {
    if (isDisabled) return (Colors.red.shade100, Colors.red.shade700, Icons.block);
    if (isSelected) return (Colors.deepPurple, Colors.white, Icons.check_circle);

    // Handle blocked status with different colors for current user vs other users
    if (status == BookingStatus.blocked) {
      if (isBlockedByCurrentUser) {
        return (Colors.orange.shade100, Colors.orange.shade700, Icons.timer); // Orange for user's own blocked slot
      } else {
        return (Colors.yellow.shade100, Colors.yellow.shade700, Icons.hourglass_empty); // Yellow for other user's blocked slot
      }
    }

    return (Colors.green.shade50, Colors.green.shade700, Icons.access_time);
  }

  String _getSlotStatusMessage(BookingStatus? status, bool isDisabled, bool isBlockedByCurrentUser) {
    if (isDisabled) return 'Not Available';

    return switch (status) {
      BookingStatus.confirmed => 'Already Booked',
      BookingStatus.blocked => isBlockedByCurrentUser
          ? 'You have already blocked - Make payment'
          : 'Blocked by other user - Make payment to make it yours',
      BookingStatus.available => 'Available for booking',
      _ => 'Available for booking',
    };
  }

}