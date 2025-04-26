import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Colors/coustcolors.dart';
import '../Providers/venues_provider.dart';
import '../providers/get_hall_booking_provider.dart';
import '../models/get_hall_booking.dart';
import 'package:intl/intl.dart';

class ManageBookingScreen extends ConsumerStatefulWidget {
  const ManageBookingScreen({super.key});

  @override
  ConsumerState<ManageBookingScreen> createState() =>
      _ManageBookingScreenState();
}

class _ManageBookingScreenState extends ConsumerState<ManageBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    // Inside your build method, add a listener to refresh when tabs change

    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to refresh state when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Explicitly refresh when tab changes
      }
    });

    // Fetch properties data for hall name mapping
    ref.read(propertyNotifierProvider.notifier).getproperty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Format date to readable format
  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return DateFormat('MMM dd, yyyy').format(parsedDate);
  }

  // Format time to 12-hour format
  String formatTime(String time) {
    final timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    final minute = timeParts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour:$minute $period';
  }

  bool isCurrentBooking(GetHallBooking booking) {
    final today = DateTime.now();

    // Parse the booking date and ensure we're only comparing the date part
    final bookingDate = DateTime.parse(booking.date);

    // Create DateTime objects with only date components for accurate comparison
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final bookingDateOnly =
        DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

    // Compare the dates (ignoring time)
    return todayDateOnly.isAtSameMomentAs(bookingDateOnly);
  }

  // Check if a booking is upcoming (future date)
  bool isUpcomingBooking(GetHallBooking booking) {
    final today = DateTime.now();
    final bookingDate = DateTime.parse(booking.date);
    return bookingDate.isAfter(today);
  }

  // Filter bookings based on tab and search query
  List<GetHallBooking> filterBookings(
      List<GetHallBooking> bookings, int tabIndex) {
    List<GetHallBooking> filteredList;

    print("Filtering for tab index: $tabIndex");
    print("Total bookings before filter: ${bookings.length}");

    switch (tabIndex) {
      case 1: // Current
        filteredList =
            bookings.where((booking) => isCurrentBooking(booking)).toList();
        print("Current bookings found: ${filteredList.length}");
        // Debug what dates are being compared
        if (filteredList.isEmpty && bookings.isNotEmpty) {
          final today = DateTime.now();
          print("Today is: ${DateFormat('yyyy-MM-dd').format(today)}");
          for (var i = 0; i < min(5, bookings.length); i++) {
            print("Booking date ${i + 1}: ${bookings[i].date}");
          }
        }
        break;
      case 2: // Upcoming
        filteredList =
            bookings.where((booking) => isUpcomingBooking(booking)).toList();
        print("Upcoming bookings found: ${filteredList.length}");
        break;
      default: // All
        filteredList = bookings;
        print("All bookings: ${filteredList.length}");
    }

    // Apply search filter if search query exists
    if (searchQuery.isNotEmpty) {
      return filteredList.where((booking) {
        final hallNameMatch = booking.hallName
                ?.toLowerCase()
                .contains(searchQuery.toLowerCase()) ??
            false;
        final propertyMatch = booking.propertyName
                ?.toLowerCase()
                .contains(searchQuery.toLowerCase()) ??
            false;
        final dateMatch = booking.date.contains(searchQuery);
        return hallNameMatch || propertyMatch || dateMatch;
      }).toList();
    }

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsyncValue = ref.watch(hallBookingsProvider);

    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 130,
            decoration: const BoxDecoration(
              color: Color(0xFF6418C3),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadiusDirectional.only(
                bottomEnd: Radius.circular(25),
                bottomStart: Radius.circular(25),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.only(top: 50.0, left: 15),
              child: Text(
                "Manage Booking",
                style: TextStyle(
                  color: CoustColors.colrEdtxt4,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Search Bar
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0.0,
                    horizontal: 16.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Current'),
                Tab(text: 'Upcoming'),
              ],
              labelColor: Color(0xFF6418C3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF6418C3),
              onTap: (_) {
                setState(() {}); // Refresh UI on tab change
              },
            ),
          ),

          // Bookings List
          Expanded(
            child: bookingsAsyncValue.when(
              data: (bookings) {
                final filteredBookings =
                    filterBookings(bookings, _tabController.index);

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF6418C3),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.propertyName ?? 'Unknown Property',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: booking.isPaid == 1
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    booking.isPaid == 1 ? 'Paid' : 'Unpaid',
                                    style: TextStyle(
                                      color: booking.isPaid == 1
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hall: ${booking.hallName ?? 'Unknown Hall'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF6418C3),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatDate(booking.date),
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF6418C3),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${formatTime(booking.slotFromTime)} - ${formatTime(booking.slotToTime)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Only show cancellation for upcoming bookings
                                if (isUpcomingBooking(booking))
                                  OutlinedButton(
                                    onPressed: () {
                                      // Show cancel confirmation dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Cancel Booking'),
                                          content: const Text(
                                            'Are you sure you want to cancel this booking?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // TODO: Implement cancel booking API call
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Booking cancelled successfully'),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Yes',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // View details - Show a bottom sheet with full details
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (context) =>
                                          DraggableScrollableSheet(
                                        initialChildSize: 0.6,
                                        maxChildSize: 0.9,
                                        minChildSize: 0.5,
                                        expand: false,
                                        builder: (context, scrollController) =>
                                            SingleChildScrollView(
                                          controller: scrollController,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Center(
                                                  child: Container(
                                                    width: 60,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[300],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                const Text(
                                                  'Booking Details',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                _detailRow(
                                                    'Property',
                                                    booking.propertyName ??
                                                        'Unknown'),
                                                _detailRow(
                                                    'Hall',
                                                    booking.hallName ??
                                                        'Unknown'),
                                                _detailRow('Date',
                                                    formatDate(booking.date)),
                                                _detailRow('Time',
                                                    '${formatTime(booking.slotFromTime)} - ${formatTime(booking.slotToTime)}'),
                                                _detailRow(
                                                    'Status',
                                                    booking.isPaid == 1
                                                        ? 'Paid'
                                                        : 'Unpaid'),
                                                _detailRow('Booking ID',
                                                    '#${booking.id}'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6418C3),
                                  ),
                                  child: const Text(
                                    'View Details',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6418C3)),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load bookings',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(hallBookingsProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6418C3),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for detail rows in bottom sheet
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
