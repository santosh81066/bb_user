import 'package:flutter/material.dart';
import 'package:bb_user/models/get_properties_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/hall_booking_provider.dart'; // Import your provider
import 'package:intl/intl.dart';

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
  DateTime _parseTime(String timeStr, DateTime baseDate) {
    final format = DateFormat.Hms(); // parses 06:00:00
    // supports '10:00 AM' format
    final parsedTime = format.parse(timeStr); // parses time into DateTime at 1970
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  String? selectedSlot;
  DateTime? selectedDay;
  Map<int, List<String>> hallTimeSlots = {};

  late List<String> years;
  // ✅ Define full month list
  final List<String> allMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late List<String> months;



  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    selectedMonth = allMonths[now.month - 1];
// default to current month
    selectedYear = now.year.toString();
    focusedDay = now;
    years = List.generate(5, (index) => (now.year + index).toString());

    _updateMonthsList();
    _updateCalendarBounds();
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

  Future<void> _bookHall(int hallId) async {
    if (selectedDay == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day and time slot')),
      );
      return;
    }

    // Extract the actual from and to time from the selected slot
    final slotParts = selectedSlot!.split('From: ')[1].split(' To: ');
    final slotFromTime = slotParts[0];
    final slotToTime = slotParts[1];

    // Format date as YYYY-MM-DD
    final formattedDate =
        "${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}";

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call the provider to make the booking
      await ref.read(hallBookingProvider.notifier).postBooking(
        hallId: hallId,
        date: formattedDate,
        slotFromTime: slotFromTime,
        slotToTime: slotToTime,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking successful!')),
      );

      // Navigate back or to a confirmation screen
      Navigator.pop(context);
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    }
  }

  // Widget to display image gallery
  Widget _buildImageGallery(Hall hall) {
    // Check if hall has images
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
                color: Colors.deepPurple,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                'https://www.gocodedesigners.com/banquetbookingz/${hall.images![imageIndex].url}',
                width: 300,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    "Image not found",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          );
        },
        controller: PageController(viewportFraction: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the booking state
    final bookingState = ref.watch(hallBookingProvider);

    final args = ModalRoute.of(context)?.settings.arguments as Map;
    final Data property = args['property'];
    final halls = property.halls ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.propertyName ?? 'No Name',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              property.address ?? 'No Address',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
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
            final isSelected = selectedIndex == index;

            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = isSelected ? null : index;
                      selectedSlot =
                      null; // Reset selected slot when changing halls
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
                              hall.hallName ?? 'No Hall Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (hall.images != null &&
                                    hall.images!.isNotEmpty)
                                  Text(
                                    '${hall.images!.length} photos',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
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
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedYear,
                                isExpanded: true,
                                items: years
                                    .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Center(child: Text(' $year')),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedYear = value!;
                                    _updateMonthsList(); // <- ADD THIS
                                    if (!months.contains(selectedMonth)) {
                                      selectedMonth = months.first; // reset month if invalid
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
                                // show month name
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
                                    selectedDay = null; // Reset selected day
                                    selectedSlot = null; // Reset selected slot
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

                            if (selectedIndex == null || hallTimeSlots[selectedIndex] == null) {
                              return true; // no slots loaded yet → keep enabled
                            }

                            final slots = hallTimeSlots[selectedIndex]!;

                            // check if ALL slots for this day are in the past
                            bool allSlotsPast = true;

                            for (var slot in slots) {
                              final slotFromTimeStr = slot.split('From: ')[1].split(' To: ')[0];
                              final slotFromTime = _parseTime(slotFromTimeStr, day);

                              if (slotFromTime.isAfter(now)) {
                                allSlotsPast = false;
                                break;
                              }
                            }

                            return !allSlotsPast; // disable if all slots past
                          },


                          onDaySelected: (selected, focused) {
                            setState(() {
                              selectedDay = selected;
                              focusedDay = focused;
                              selectedSlot = null; // Reset selected slot
                              final hall = halls[selectedIndex!];

                              final slots = hall.slots?.map((slot) {
                                return 'From: ${slot.slotFromTime ?? ''} To: ${slot.slotToTime ?? ''}';
                              }).toList() ?? [];

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
                                  color: Colors.deepPurple,
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

                        if (selectedDay != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Available Time Slots on ${selectedDay!.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if ((hallTimeSlots[selectedIndex] ?? [])
                              .isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                  'No time slots available for this day'),
                            )
                          else ...[
                            ...((hallTimeSlots[selectedIndex] ?? []).map((slot) {
                              final now = DateTime.now();
                              final isToday = selectedDay != null &&
                                  selectedDay!.year == now.year &&
                                  selectedDay!.month == now.month &&
                                  selectedDay!.day == now.day;

                              final slotFromTimeStr = slot.split('From: ')[1].split(' To: ')[0];

                              final slotFromTime = _parseTime(slotFromTimeStr, selectedDay!);

                              bool isDisabled = false;
                              if (isToday && slotFromTime.isBefore(now)) {
                                isDisabled = true;
                              }

                              return RadioListTile<String>(
                                value: slot,
                                groupValue: selectedSlot,
                                title: Text(
                                  slot + (isDisabled ? ' (Past)' : ''),
                                  style: TextStyle(
                                    color: isDisabled ? Colors.grey : null,
                                  ),
                                ),
                                activeColor: Colors.deepPurple,
                                onChanged: isDisabled
                                    ? null
                                    : (value) {
                                  setState(() {
                                    selectedSlot = value;
                                  });
                                },
                              );
                            }))
                          ],



                          if (selectedSlot != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: bookingState is AsyncLoading
                                      ? null // Disable button during loading
                                      : () => _bookHall(hall.hallId ?? 0),
                                  child: const Text('Confirm Booking',
                                      style:
                                      TextStyle(color: Colors.white)),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  )
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