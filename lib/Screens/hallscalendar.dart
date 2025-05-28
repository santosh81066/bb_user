import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bb_user/models/get_properties_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/auth.dart';
import '../Providers/hall_booking_provider.dart';
import '../Widgets/buildhallfeatures.dart';
import '../Widgets/dateselection.dart';
import '../Widgets/hall_selection.dart';
import '../Widgets/slotselection.dart';
import '../models/hall_booking.dart';
import '../utils/bbapi.dart';

class StepByStepHallBookingScreen extends ConsumerStatefulWidget {
  const StepByStepHallBookingScreen({super.key});

  @override
  ConsumerState<StepByStepHallBookingScreen> createState() => _StepByStepHallBookingScreenState();
}

class _StepByStepHallBookingScreenState extends ConsumerState<StepByStepHallBookingScreen>
    with TickerProviderStateMixin {
  int currentStep = 0, selectedHallIndex = 0;
  late String selectedYear, selectedMonth;
  late DateTime focusedDay, firstDay, lastDay;
  DateTime? selectedDay;
  String? selectedSlot;
  Map<String, BookingStatus> bookingStatuses = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PageController _hallPageController = PageController();

  late List<String> years;
  static const allMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  late List<String> months;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hallPageController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final now = DateTime.now();
    selectedMonth = allMonths[now.month - 1];
    selectedYear = now.year.toString();
    focusedDay = now;
    years = List.generate(5, (i) => (now.year + i).toString());
    _updateMonthsList();
    _updateCalendarBounds();
    _loadExistingBookings();
  }

  BookingStatus _mapStatusCode(String code) => switch (code) {
    'c' => BookingStatus.confirmed,
    'b' => BookingStatus.blocked,
    _ => BookingStatus.available,
  };

  void _loadExistingBookings() async {
    try {
      final authState = ref.read(authprovider);
      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: {'Authorization': 'Bearer ${authState.token}', 'Content-Type': 'application/json'},
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

  void _updateCalendarBounds() {
    int year = int.parse(selectedYear);
    int month = allMonths.indexOf(selectedMonth) + 1;
    firstDay = DateTime(year, month, 1);
    lastDay = DateTime(year, month + 1, 0);
    focusedDay = firstDay;
  }

  void _updateMonthsList() {
    final now = DateTime.now();
    months = int.parse(selectedYear) == now.year ?
    allMonths.sublist(now.month - 1) : List.from(allMonths);
  }

  String _getBookingKey(int hallId, String date, String fromTime, String toTime) =>
      '$hallId-$date-$fromTime-$toTime';

  void _nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _animationController.reset();
      _animationController.forward();
    }
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

  void _handlePaymentSuccess(Hall hall, String date, String fromTime, String toTime) async {
    final bookingKey = _getBookingKey(hall.hallId ?? 0, date, fromTime, toTime);

    try {
      final authState = ref.read(authprovider);
      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: {'Authorization': 'Bearer ${authState.token}', 'Content-Type': 'application/json'},
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
              decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Booking Confirmed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Your hall has been successfully booked.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
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

  Widget _buildStep1(List<Hall> halls) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader('Choose Your Perfect Hall', Icons.home_work),
          const SizedBox(height: 20),
          SizedBox(
            height: 500,
            child: PageView.builder(
              controller: _hallPageController,
              onPageChanged: (index) => setState(() => selectedHallIndex = index),
              itemCount: halls.length,
              itemBuilder: (context, index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: selectedHallIndex == index ? 10 : 20,
                  vertical: selectedHallIndex == index ? 0 : 20,
                ),
                child: HallSelection(hall: halls[index], isSelected: selectedHallIndex == index),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildIndicator(halls.length),
        ],
      ),
    );
  }

  Widget _buildIndicator(int count) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(count, (index) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: selectedHallIndex == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: selectedHallIndex == index ? Colors.deepPurple : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    )),
  );

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

  Widget _iconContainer(IconData icon, [Color? backgroundColor]) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: backgroundColor ?? Colors.deepPurple.shade100,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: backgroundColor != null ? Colors.white : Colors.deepPurple, size: 24),
  );

  Widget _buildStepIndicator() => Container(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: List.generate(4, (index) {
        bool isCompleted = index < currentStep;
        bool isCurrent = index == currentStep;

        return Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent ? Colors.deepPurple : Colors.grey.shade300,
                  boxShadow: isCompleted || isCurrent ? [
                    BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ] : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text('${index + 1}',
                      style: TextStyle(
                          color: isCompleted || isCurrent ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              if (index < 3)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.deepPurple : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    ),
  );

  Widget _buildNavigationButtons() => Container(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        if (currentStep > 0) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleNextButton,
            icon: Icon(currentStep == 3 ? Icons.payment : Icons.arrow_forward),
            label: Text(currentStep == 3 ? 'Proceed to Payment' : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
          ),
        ),
      ],
    ),
  );

  void _handleNextButton() {
    if (currentStep == 2 && selectedDay == null) {
      _showSnackBar('Please select a date');
      return;
    }
    if (currentStep == 3 && selectedSlot == null) {
      _showSnackBar('Please select a time slot');
      return;
    }
    currentStep == 3 ? _goToPayment() : _nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map;
    final Data property = args['property'];
    final halls = property.halls ?? [];

    if (halls.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hall Booking')),
        body: _buildEmpty('No halls found for this property', Icons.error_outline),
      );
    }

    final selectedHall = halls[selectedHallIndex];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.propertyName ?? 'Hall Booking',
              style: const TextStyle(fontSize: 18, color: Colors.deepPurple, fontWeight: FontWeight.bold),
            ),
            if (property.address != null)
              Text(property.address!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: switch (currentStep) {
                  0 => _buildStep1(halls),
                  1 => EnhancedHallFeatures(selectedHall),
                  2 => Dateselection(
                    selectedDay: selectedDay,
                    selectedYear: selectedYear,
                    selectedMonth: selectedMonth,
                    onDateSelected: (date) => setState(() => selectedDay = date),
                    onYearChanged: (year) {
                      setState(() {
                        selectedYear = year;
                        _updateMonthsList();
                        if (!months.contains(selectedMonth)) selectedMonth = months.first;
                        _updateCalendarBounds();
                        selectedDay = null;
                      });
                    },
                    onMonthChanged: (month) {
                      setState(() {
                        selectedMonth = month;
                        _updateCalendarBounds();
                        selectedDay = null;
                      });
                    },
                  ),
                  3 => Slotselection(
                    hall: selectedHall,
                    selectedDay: selectedDay,
                    selectedSlot: selectedSlot,
                    bookingStatuses: bookingStatuses,
                    onSlotSelected: (slot) => setState(() => selectedSlot = slot),
                  ),
                  _ => const SizedBox(),
                },
              ),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
}