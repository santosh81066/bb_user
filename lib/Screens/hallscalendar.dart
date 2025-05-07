import 'package:flutter/material.dart';
import 'package:bb_user/models/get_properties_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/hall_booking_provider.dart';
import 'package:intl/intl.dart';

class HallsCalendarScreen extends ConsumerStatefulWidget {
  const HallsCalendarScreen({super.key});

  @override
  ConsumerState<HallsCalendarScreen> createState() => _HallsCalendarScreenState();
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

  // For month/year selection
  late List<String> years;
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

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(hallBookingProvider.notifier).postBooking(
        id: DateTime.now().millisecondsSinceEpoch,
        hallId: hall.hallId ?? 0,
        date: formattedDate,
        slotFromTime: slotFromTime,
        slotToTime: slotToTime,
        isBlocked: true,
        isPaid: false,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot blocked successfully!')),
        );

        // Navigate to payment page after booking success
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
          },
        );
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
                'https://www.gocodedesigners.com/banquetbookingz/${hall.images![imageIndex].url}',
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

  Widget _buildHallFeatures(Hall hall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hall Features',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildFeatureChip(hall.capacity != null, 'Capacity: ${hall.capacity ?? 0}'),
            _buildFeatureChip(hall.cctv == true, 'CCTV Available'),
            _buildFeatureChip(hall.fireAlarm == true, 'Fire Alarm'),
            _buildFeatureChip(hall.soundSystem == true, 'Sound System'),
            _buildFeatureChip(hall.wifiAvailable == true, 'WiFi Available'),
            _buildFeatureChip(hall.projectorAvailable == true, 'Projector'),
            _buildFeatureChip(hall.microphoneAvailable == true, 'Microphone'),
            _buildFeatureChip(hall.valetParking == true, 'Valet Parking'),
            _buildFeatureChip(hall.outsideFood == true, 'Outside Food Allowed'),
            _buildFeatureChip(hall.allowAlcohol == true, 'Alcohol Allowed'),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureChip(bool isAvailable, String label) {
    return Chip(
      label: Text(label),
      backgroundColor: isAvailable ? Colors.green[100] : Colors.grey[300],
      labelStyle: TextStyle(
        color: isAvailable ? Colors.green[800] : Colors.grey[600],
        fontSize: 12,
      ),
    );
  }

  Widget _buildPriceInfo(Hall hall) {
    return Row(
      children: [
        Icon(Icons.monetization_on, color: Colors.amber[700]),
        const SizedBox(width: 4),
        Text(
          '₹${hall.price ?? 0}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.amber[700],
          ),
        ),
        const Spacer(),
        if (hall.parkingCapacity != null && hall.parkingCapacity! > 0)
          Row(
            children: [
              const Icon(Icons.local_parking, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'Parking: ${hall.parkingCapacity}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
                final slotFromTime = _parseTime(slotFromTimeStr, selectedDay!);

                bool isDisabled = isToday && slotFromTime.isBefore(now);

                return RadioListTile<String>(
                  value: slot,
                  groupValue: selectedSlot,
                  title: Text(
                    slot,
                    style: TextStyle(
                      color: isDisabled ? Colors.grey : null,
                      fontWeight: selectedSlot == slot ? FontWeight.bold : null,
                    ),
                  ),
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: isDisabled
                      ? null
                      : (value) {
                    setState(() {
                      selectedSlot = value;
                    });
                  },
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
                child: Text(
                  'Book Hall for ₹${hall.price ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      border: Border.all(color: Colors.deepPurple.shade200, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildImageGallery(hall),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                if (hall.images != null && hall.images!.isNotEmpty)
                                  Text(
                                    '${hall.images!.length} photos',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Icon(
                                  isSelected ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.deepPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildPriceInfo(hall),
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
                      border: Border.all(color: Colors.deepPurple.shade100),
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