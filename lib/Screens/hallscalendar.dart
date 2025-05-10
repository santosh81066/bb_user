import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bb_user/models/get_properties_model.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/auth.dart';
import '../Providers/hall_booking_provider.dart';
import 'package:intl/intl.dart';

import '../models/hall_booking.dart';
import '../utils/bbapi.dart';

class HallsCalendarScreen extends ConsumerStatefulWidget {
  const HallsCalendarScreen({super.key});

  @override
  ConsumerState<HallsCalendarScreen> createState() =>
      _HallsCalendarScreenState();
}

class _HallsCalendarScreenState extends ConsumerState<HallsCalendarScreen> {
  int? selectedIndex;
  late String selectedYear;
  late String selectedMonth;
  late DateTime focusedDay;
  late DateTime firstDay;
  late DateTime lastDay;
  DateTime? selectedDay;
  String? selectedSlot;
  Map<int, List<String>> hallTimeSlots = {};
  Map<String, BookingStatus> bookingStatuses = {};


  // For month/year selection
  late List<String> years;
  final List<String> allMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  late List<String> months;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    selectedMonth = allMonths[now.month - 1];
    selectedYear = now.year.toString();
    focusedDay = now;
    years = List.generate(5, (index) => (now.year + index).toString());

    _updateMonthsList();
    _updateCalendarBounds();
    _loadExistingBookings();
  }
  BookingStatus _mapStatusCode(String code) {
    switch (code) {
      case 'c':
        return BookingStatus.confirmed;
      case 'b':
        return BookingStatus.blocked;
      case '0':
      default:
        return BookingStatus.available;
    }
  }

  // Update the code that loads existing bookings
  void _loadExistingBookings() async {
    try {
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
        final responseData = jsonDecode(response.body);

        // Extract booking data
        final List bookings = responseData['data'] as List;
        final updatedStatuses = <String, BookingStatus>{};

        for (var booking in bookings) {
          final hallId = booking['hall_id'];
          final date = booking['date'];
          final fromTime = booking['slot_from_time'];
          final toTime = booking['slot_to_time'];
          final statusCode = booking['is_paid'];

          final key = _getBookingKey(hallId, date, fromTime, toTime);
          updatedStatuses[key] = _mapStatusCode(statusCode);
        }

        setState(() {
          bookingStatuses = updatedStatuses;
        });



      } else {
        throw Exception("Failed to load booking statuses");
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
    if (int.parse(selectedYear) == now.year) {
      // if current year, show from current month onward
      months = allMonths.sublist(now.month - 1);
    } else {
      // if different year, show all months
      months = List.from(allMonths);
    }
  }

  DateTime _parseTime(String timeStr, DateTime baseDate) {
    final format = DateFormat.Hms(); // parses 06:00:00
    final parsedTime = format.parse(timeStr);
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }
  String _getBookingKey(int hallId, String date, String fromTime, String toTime) {
    return '$hallId-$date-$fromTime-$toTime';
  }
  // Update the _bookHall method in your HallsCalendarScreen class
  Future<void> _bookHall(Hall hall) async {
    if (selectedDay == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day and time slot')),
      );
      return;
    }

    final slotParts = selectedSlot!.split('From: ')[1].split(' To: ');
    final slotFromTime = slotParts[0];
    final slotToTime = slotParts[1];

    final formattedDate =
        "${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}";
    final bookingKey = _getBookingKey(hall.hallId ?? 0, formattedDate, slotFromTime, slotToTime);
    final currentStatus = bookingStatuses[bookingKey] ?? BookingStatus.available;

    // Check if the slot is already confirmed
    if (currentStatus == BookingStatus.confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This time slot is already booked')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // If the slot is already blocked, proceed to payment directly
      if (currentStatus == BookingStatus.blocked) {
        if (context.mounted) {
          Navigator.of(context).pop(); // close loading dialog
          _navigateToPayment(hall, formattedDate, slotFromTime, slotToTime);
        }
        return;
      }

      // For a new booking, first mark it as blocked
      await ref.read(hallBookingProvider.notifier).postBooking(
        hallId: hall.hallId ?? 0,
        bookingId: null, // This is a new booking
        date: formattedDate,
        slotFromTime: slotFromTime,
        slotToTime: slotToTime,
        isPaid: bookingStatusToString(BookingStatus.blocked),        // Mark as blocked "b"
      );

      // Update local state immediately
      setState(() {
        bookingStatuses[bookingKey] = BookingStatus.blocked;
      });

      if (context.mounted) {
        Navigator.of(context).pop(); // close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot blocked successfully!')),
        );

        // Navigate to payment page
        _navigateToPayment(hall, formattedDate, slotFromTime, slotToTime);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.toString()}')),
        );
      }
    }
  }
  void _navigateToPayment(Hall hall, String formattedDate, String slotFromTime, String slotToTime) {
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'hallId': hall.hallId,
        'date': formattedDate,
        'slotFromTime': slotFromTime,
        'slotToTime': slotToTime,
        'hallName': hall.name,
        'price': hall.price,
        'onPaymentSuccess': (bool success) {
          if (success) {
            _handlePaymentSuccess(hall, formattedDate, slotFromTime, slotToTime);
          }
        },
      },
    );
  }

// Update the _handlePaymentSuccess method
  void _handlePaymentSuccess(Hall hall, String date, String fromTime, String toTime) async {
    final bookingKey = _getBookingKey(hall.hallId ?? 0, date, fromTime, toTime);

    try {
      final authState = ref.read(authprovider);
      final headers = {
        'Authorization': 'Bearer ${authState.token}',
        'Content-Type': 'application/json',
      };

      // Get all bookings to find our booking ID
      final response = await http.get(
        Uri.parse(Bbapi.hallbooking),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to retrieve booking data");
      }

      final responseData = jsonDecode(response.body);
      final List bookings = responseData['data'] as List;
      int? bookingId;

      // Find the booking that matches our criteria
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

      if (bookingId == null) {
        throw Exception("Booking not found for payment update.");
      }

      // Update the booking to confirmed status
      await ref.read(hallBookingProvider.notifier).updateBookingPaymentStatus(
        bookingId: bookingId,
        status: bookingStatusToString(BookingStatus.confirmed),
      );


      // Update local state
      setState(() {
        bookingStatuses[bookingKey] = BookingStatus.confirmed as BookingStatus;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful! Your booking is confirmed.')),
        );
      }

      // Refresh booking data
      _loadExistingBookings();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment update failed: ${e.toString()}')),
        );
      }
    }
  }


  Widget _buildImageGallery(Hall hall) {
    if (hall.images == null || hall.images!.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('No images available')),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: hall.images!.length,
        itemBuilder: (context, imageIndex) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                'http://www.gocodedesigners.com/banquetbookingz/${hall.images![imageIndex].url}',
                width: 300,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    "Image not found",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          );
        },
        controller: PageController(viewportFraction: 0.9),
      ),
    );
  }

//hall section
  Widget _buildHallFeatures(Hall hall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Hall Features',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.deepPurple,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Scrollable container for features
        Container(
          height: 350, // Set a fixed height to make it scrollable
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.shade100, width: 1),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<int>(
                    future: ref
                        .read(hallBookingProvider.notifier)
                        .countUniqueBlockedUsersPerDay(hall.hallId ?? 0),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Text("Loading user block info...", style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),));
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else if (snapshot.hasData) {
                        final uniqueUserCount = snapshot.data!;
                        return Center(
                          child: Text(
                            "No.oF Users Blocked : $uniqueUserCount",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        );
                      } else {
                        return const Text("No data available");
                      }
                    },
                  ),

                  const SizedBox(height: 8),
                  _buildSectionTitle('Basic Information'),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureItem(
                          hall.capacity != null && hall.capacity! > 0,
                          'Capacity: ${hall.capacity ?? 0}',
                          Icons.chair_outlined),
                      _buildFeatureItem(
                        hall.parkingCapacity != null &&
                            hall.parkingCapacity! > 0,
                        'Parking: ${hall.parkingCapacity ?? 0}',
                        Icons.local_parking,
                      ),
                      _buildFeatureItem(
                          hall.floatingCapacity != null &&
                              hall.floatingCapacity! > 0,
                          'Floating: ${hall.floatingCapacity ?? 0}',
                          Icons.man),
                      _buildFeatureItem(
                        hall.foodtype != null && hall.foodtype!.isNotEmpty,
                        'Food: ${hall.foodtype ?? 'Not specified'}',
                        Icons.restaurant,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Amenities'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureItem(
                        hall.cctv == true,
                        'CCTV Available',
                        Icons.videocam,
                      ),
                      _buildFeatureItem(
                        hall.fireAlarm == true,
                        'Fire Alarm',
                        Icons.warning,
                      ),
                      _buildFeatureItem(
                        hall.soundSystem == true,
                        'Sound System',
                        Icons.volume_up,
                      ),
                      _buildFeatureItem(
                        hall.wifiAvailable == true,
                        'WiFi Available',
                        Icons.wifi,
                      ),
                      _buildFeatureItem(
                        hall.projectorAvailable == true,
                        'Projector',
                        Icons.video_label,
                      ),
                      _buildFeatureItem(
                        hall.microphoneAvailable == true,
                        'Microphone',
                        Icons.mic,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Policies'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureItem(
                        hall.valetParking == true,
                        'Valet Parking',
                        Icons.local_parking,
                      ),
                      _buildFeatureItem(
                        hall.outsideFood == true,
                        'Outside Food',
                        Icons.fastfood,
                      ),
                      _buildFeatureItem(
                        hall.allowAlcohol == true,
                        'Alcohol Allowed',
                        Icons.local_bar,
                      ),
                      _buildFeatureItem(
                        hall.allowOutsideDecorators == true,
                        'Outside Decorators',
                        Icons.celebration,
                      ),
                      _buildFeatureItem(
                        hall.allowOutsideDj == true,
                        'Outside DJ',
                        Icons.music_note,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Safety & Security'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureItem(
                        hall.emergencyExits != null && hall.emergencyExits! > 0,
                        'Exits: ${hall.emergencyExits ?? 0}',
                        Icons.exit_to_app,
                      ),
                      _buildFeatureItem(
                        hall.securityCount != null && hall.securityCount! > 0,
                        'Security: ${hall.securityCount ?? 0}',
                        Icons.security,
                      ),
                      _buildFeatureItem(
                        hall.securityLevel != null &&
                            hall.securityLevel!.isNotEmpty,
                        'Level: ${hall.securityLevel ?? 'Basic'}',
                        Icons.shield,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Staff & Maintenance'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureItem(
                        hall.staffCount != null && hall.staffCount! > 0,
                        'Staff: ${hall.staffCount ?? 0}',
                        Icons.people_outline,
                      ),
                      _buildFeatureItem(
                        hall.cleaningStaff != null && hall.cleaningStaff! > 0,
                        'Cleaning: ${hall.cleaningStaff ?? 0}',
                        Icons.cleaning_services,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle('Additional Costs'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildFeatureItem(
                        hall.cleaningCost != null && hall.cleaningCost! > 0,
                        'Cleaning: ₹${hall.cleaningCost ?? 0}',
                        Icons.cleaning_services_outlined,
                      ),
                      _buildFeatureItem(
                        hall.securityCost != null && hall.securityCost! > 0,
                        'Security: ₹${hall.securityCost ?? 0}',
                        Icons.security_outlined,
                      ),
                      _buildFeatureItem(
                        hall.decorCost != null && hall.decorCost! > 0,
                        'Decor: ₹${hall.decorCost ?? 0}',
                        Icons.brush,
                      ),
                      _buildFeatureItem(
                        hall.additionalServicesCost != null &&
                            hall.additionalServicesCost! > 0,
                        'Additional: ₹${hall.additionalServicesCost ?? 0}',
                        Icons.miscellaneous_services,
                      ),
                    ],
                  ),

                  // Sound system details if available
                  if (hall.soundSystemDetails != null &&
                      hall.soundSystemDetails!.isNotEmpty)
                    _buildDetailSection(
                      'Sound System Details',
                      hall.soundSystemDetails!,
                      Icons.music_note,
                    ),

                  // Lighting system details if available
                  if (hall.lightingSystemDetails != null &&
                      hall.lightingSystemDetails!.isNotEmpty)
                    _buildDetailSection(
                      'Lighting System Details',
                      hall.lightingSystemDetails!,
                      Icons.light,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple.shade800,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String details, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.green[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    details,
                    style: TextStyle(
                      color: Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(bool isAvailable, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: isAvailable
            ? LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isAvailable
            ? [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
            : [
          BoxShadow(
            color: Colors.red.shade100.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(left: 8, right: 4),
            decoration: BoxDecoration(
              color: isAvailable
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  color:
                  isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

//price
  Widget _buildPriceInfo(Hall hall) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //Icon(Icons.monetization_on, color: Colors.amber[700]),
        const Text(
          'Price : ',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '₹${hall.price ?? 0}',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Colors.amber[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(Hall hall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: selectedYear,
                isExpanded: true,
                items: years
                    .map((year) => DropdownMenuItem(
                  value: year,
                  child: Center(child: Text(year)),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value!;
                    _updateMonthsList();
                    if (!months.contains(selectedMonth)) {
                      selectedMonth = months.first;
                    }
                    _updateCalendarBounds();
                    selectedDay = null;
                    selectedSlot = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: selectedMonth,
                isExpanded: true,
                items: months
                    .map((month) => DropdownMenuItem(
                  value: month,
                  child: Center(child: Text(month)),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value!;
                    _updateCalendarBounds();
                    selectedDay = null;
                    selectedSlot = null;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TableCalendar(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          calendarFormat: CalendarFormat.month,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
          ),
          headerVisible: false,
          enabledDayPredicate: (day) {
            final now = DateTime.now();
            final todayDate = DateTime(now.year, now.month, now.day);

            if (day.isBefore(todayDate)) {
              return false; // past date → disable
            }
            return true;
          },
          onDaySelected: (selected, focused) {
            setState(() {
              selectedDay = selected;
              focusedDay = focused;
              selectedSlot = null; // Reset selected slot

              final slots = hall.slots?.map((slot) {
                return 'From: ${slot.slotFromTime ?? ''} To: ${slot.slotToTime ?? ''}';
              }).toList() ??
                  [];

              hallTimeSlots[selectedIndex!] = slots;
            });
          },
          calendarBuilders: CalendarBuilders(
            disabledBuilder: (context, day, focusedDay) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            defaultBuilder: (context, day, focusedDay) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Update the _buildTimeSlots method to properly show booking status
  Widget _buildTimeSlots(Hall hall) {
    if (selectedDay == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Available Time Slots on ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDay!)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if ((hallTimeSlots[selectedIndex] ?? []).isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No time slots available for this day'),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: (hallTimeSlots[selectedIndex] ?? []).map((slot) {
                final now = DateTime.now();
                final isToday = selectedDay!.year == now.year &&
                    selectedDay!.month == now.month &&
                    selectedDay!.day == now.day;

                final slotFromTimeStr = slot.split('From: ')[1].split(' To: ')[0];
                final slotToTimeStr = slot.split(' To: ')[1];

                final slotFromTime = _parseTime(slotFromTimeStr, selectedDay!);

                final formattedDate = "${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}";
                final bookingKey = _getBookingKey(hall.hallId ?? 0, formattedDate, slotFromTimeStr, slotToTimeStr);
                final bookingStatus = bookingStatuses[bookingKey];

                // Determine if the slot should be disabled
                bool isDisabled = isToday && slotFromTime.isBefore(now) ||
                    bookingStatus == BookingStatus.confirmed;

                // Style based on booking status
                Color? slotColor;
                if (bookingStatus == BookingStatus.confirmed) {
                  slotColor = Colors.red[100];
                } else if (bookingStatus == BookingStatus.blocked) {
                  slotColor = Colors.amber[100];
                } else {
                  slotColor = Colors.green[50]; // Available
                }

                return Container(
                  color: slotColor,
                  child: RadioListTile<String>(
                    value: slot,
                    groupValue: selectedSlot,
                    title: Text(
                      slot,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey : null,
                        fontWeight: selectedSlot == slot ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: _getSlotStatusText(
                      bookingStatus,
                      hall.hallId ?? 0,
                      formattedDate,
                      slotFromTimeStr,
                      slotToTimeStr,
                    ),

                    activeColor: Theme.of(context).primaryColor,
                    onChanged: isDisabled
                        ? null
                        : (value) {
                      setState(() {
                        selectedSlot = value;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        if (selectedSlot != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: ref.watch(hallBookingProvider) is AsyncLoading
                    ? null
                    : () => _bookHall(hall),
                child: _getBookingButtonText(hall),
              ),
            ),
          ),
      ],
    );
  }

  Widget? _getSlotStatusText(BookingStatus? status, int hallId, String date, String fromTime, String toTime) {
    if (status == BookingStatus.confirmed) {
      return const Text('Already Booked', style: TextStyle(color: Colors.red));
    } else if (status == BookingStatus.blocked) {
      return FutureBuilder<int>(
        future: ref.read(hallBookingProvider.notifier).countUsersBlockedSameSlot(
          hallId: hallId,
          date: date,
          fromTime: fromTime,
          toTime: toTime,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading...', style: TextStyle(color: Colors.amber));
          } else if (snapshot.hasError) {
            return Text('Error', style: TextStyle(color: Colors.red));
          } else {
            return Text('${snapshot.data} users blocked this slot', style: TextStyle(color: Colors.amber));
          }
        },
      );
    }
    return const Text('Available', style: TextStyle(color: Colors.green));
  }



  Widget _getBookingButtonText(Hall hall) {
    if (selectedDay == null || selectedSlot == null) return const Text('Book Hall');

    final slotParts = selectedSlot!.split('From: ')[1].split(' To: ');
    final slotFromTime = slotParts[0];
    final slotToTime = slotParts[1];
    final formattedDate = "${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}";
    final bookingKey = _getBookingKey(hall.hallId ?? 0, formattedDate, slotFromTime, slotToTime);
    final bookingStatus = bookingStatuses[bookingKey] ?? BookingStatus.available;

    if (bookingStatus == BookingStatus.blocked) {
      return Text(
        'Pay for Booking ₹${hall.price ?? 0}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(
        'Book Hall for ₹${hall.price ?? 0}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map;
    final Data property = args['property'];
    final halls = property.halls ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.propertyName ?? 'No Name',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (property.address != null)
              Text(
                property.address!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: halls.isNotEmpty
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: halls.length,
          itemBuilder: (context, index) {
            final hall = halls[index];
            final hallId = hall.hallId ?? 0;

            final isSelected = selectedIndex == index;

            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = isSelected ? null : index;
                      selectedSlot = null; // Reset selected slot
                      if (!isSelected && hall.slots != null) {
                        final slots = hall.slots!.map((slot) {
                          return 'From: ${slot.slotFromTime ?? ''} To: ${slot.slotToTime ?? ''}';
                        }).toList();
                        hallTimeSlots[index] = slots;
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      border: Border.all(
                          color: Colors.deepPurple.shade200, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildImageGallery(hall),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hall.name ?? 'No Hall Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),


                            Row(
                              children: [
                                // if (hall.images != null &&
                                //     hall.images!.isNotEmpty)
                                //   Text(
                                //     '${hall.images!.length} photos',
                                //     style: TextStyle(
                                //       color: Colors.grey[600],
                                //       fontSize: 12,
                                //     ),
                                //   ),
                                _buildPriceInfo(hall),
                                const SizedBox(width: 8),
                                Icon(
                                  isSelected
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.deepPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // _buildPriceInfo(hall),
                      ],
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                      Border.all(color: Colors.deepPurple.shade100),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHallFeatures(hall),
                        const Divider(height: 32),
                        _buildCalendarSection(hall),
                        _buildTimeSlots(hall),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      )
          : const Center(
        child: Text('No halls found for this property'),
      ),
    );
  }
}