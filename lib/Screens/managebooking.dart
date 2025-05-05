import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Colors/coustcolors.dart';
import '../Providers/get_hall_booking_provider.dart';
import '../Providers/venues_provider.dart';
import '../models/get_hall_booking.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

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
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Updated to 3 tabs

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Explicitly refresh when tab changes
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // This ensures we only load data once when the widget is first built
    if (_isFirstLoad) {
      _loadData();
      _isFirstLoad = false;
    }
  }

  // Explicit method to load all required data
  Future<void> _loadData() async {
    // Show a loading indicator if needed

    // First load properties
    await ref.read(propertyNotifierProvider.notifier).getproperty();

    // Then load bookings
    await ref.read(gethallBookingsNotifierProvider.notifier).loadBookings();
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
    final bookingDate = DateTime.parse(booking.date);
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final bookingDateOnly =
        DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
    return todayDateOnly.isAtSameMomentAs(bookingDateOnly);
  }

  // Check if a booking is upcoming (future date)
  bool isUpcomingBooking(GetHallBooking booking) {
    final today = DateTime.now();
    final bookingDate = DateTime.parse(booking.date);
    return bookingDate.isAfter(today);
  }

  // Check if a booking is completed (past date)
  bool isCompletedBooking(GetHallBooking booking) {
    final today = DateTime.now();
    final bookingDate = DateTime.parse(booking.date);
    final bookingEndTime = booking.slotToTime.split(':');
    final bookingEndHour = int.parse(bookingEndTime[0]);
    final bookingEndMinute = int.parse(bookingEndTime[1]);

    // Create a DateTime object for the end of the booking
    final bookingEndDateTime = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      bookingEndHour,
      bookingEndMinute,
    );

    return bookingEndDateTime.isBefore(today);
  }

  // Filter bookings based on tab and search query
  List<GetHallBooking> filterBookings(
      List<GetHallBooking> bookings, int tabIndex) {
    List<GetHallBooking> filteredList;

    switch (tabIndex) {
      case 1: // Upcoming
        filteredList =
            bookings.where((booking) => isUpcomingBooking(booking)).toList();
        break;
      case 2: // Completed
        filteredList =
            bookings.where((booking) => isCompletedBooking(booking)).toList();
        break;
      default: // All
        filteredList = bookings;
    }

    // Apply search filter if search query exists
    if (searchQuery.isNotEmpty) {
      filteredList = filteredList.where((booking) {
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

    // Sort bookings by date (and time) in descending order (latest first)
    filteredList.sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);

      // If dates are the same, sort by time
      if (dateA
          .isAtSameMomentAs(DateTime(dateB.year, dateB.month, dateB.day))) {
        final timeA = a.slotFromTime.split(':');
        final timeB = b.slotFromTime.split(':');

        final hourA = int.parse(timeA[0]);
        final hourB = int.parse(timeB[0]);

        if (hourA != hourB) {
          return hourB.compareTo(hourA); // Later hour first
        }

        final minuteA = int.parse(timeA[1]);
        final minuteB = int.parse(timeB[1]);
        return minuteB.compareTo(minuteA); // Later minute first
      }

      // Otherwise sort by date
      return dateB.compareTo(dateA); // Latest date first
    });

    return filteredList;
  }

  // Method to navigate to review page with appropriate ID
  void _navigateToReview(String type, GetHallBooking booking) {
    if (type == 'property') {
      // Get property ID from the properties list based on property name
      final propertiesState = ref.read(propertyNotifierProvider);
      final property = propertiesState.data?.firstWhereOrNull(
        (prop) => prop.propertyName == booking.propertyName,
      );

      if (property != null) {
        // Navigate to property review page with property ID
        Navigator.pushNamed(
          context,
          '/review',
          arguments: {
            'type': 'property',
            'id': property.propertyId,
            'name': booking.propertyName,
          },
        );
        print("${property.propertyId}");
      } else {
        // Show error message if property not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property information not found'),
          ),
        );
      }
    } else if (type == 'hall') {
      // Navigate to hall review page with hall ID
      Navigator.pushNamed(
        context,
        '/review',
        arguments: {
          'type': 'hall',
          'id': booking.hallId,
          'name': booking.hallName,
        },
      );
      print("${booking.hallId}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsyncValue = ref.watch(gethallBookingsNotifierProvider);

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
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
              labelColor: Color(0xFF6418C3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF6418C3),
              labelPadding: EdgeInsets.symmetric(horizontal: 25),
              tabAlignment: TabAlignment.center,
              isScrollable: true, // Allow tabs to scroll if needed
              onTap: (_) {
                setState(() {}); // Refresh UI on tab change
              },
            ),
          ),

          // Bookings List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Color(0xFF6418C3),
              child: bookingsAsyncValue.when(
                data: (bookings) {
                  final filteredBookings =
                      filterBookings(bookings, _tabController.index);

                  if (filteredBookings.isEmpty) {
                    return ListView(
                      // Wrap in ListView for RefreshIndicator to work
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _tabController.index == 2
                                      ? Icons.event_available
                                      : Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _tabController.index == 2
                                      ? 'No completed bookings found'
                                      : 'No bookings found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      final isCompleted = _tabController.index == 2 ||
                          isCompletedBooking(booking);

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
                                      booking.propertyName ??
                                          'Unknown Property',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: Colors.green.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Completed',
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
                              // Action buttons - Only show for non-completed bookings
                              if (!isCompleted)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isUpcomingBooking(booking))
                                      OutlinedButton(
                                        onPressed: () {
                                          // Show cancel confirmation dialog
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text('Cancel Booking'),
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
                                                    ScaffoldMessenger.of(
                                                            context)
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
                                          side: const BorderSide(
                                              color: Colors.red),
                                        ),
                                        child: const Text('Cancel'),
                                      ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showBookingDetails(context, booking);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF6418C3),
                                      ),
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              // For completed bookings, show review and view details buttons
                              if (isCompleted)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Add Review dropdown button
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: const Color(0xFF6418C3)),
                                      ),
                                      child: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          // Navigate to review page with the appropriate ID
                                          _navigateToReview(value, booking);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'property',
                                            child: Row(
                                              children: [
                                                Icon(Icons.home, size: 18),
                                                SizedBox(width: 8),
                                                Text('For Property'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'hall',
                                            child: Row(
                                              children: [
                                                Icon(Icons.meeting_room,
                                                    size: 18),
                                                SizedBox(width: 8),
                                                Text('For Hall'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0, vertical: 8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.rate_review,
                                                size: 16,
                                                color: Color(0xFF6418C3),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Add Review',
                                                style: TextStyle(
                                                  color: Color(0xFF6418C3),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_drop_down,
                                                color: Color(0xFF6418C3),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // View Details button
                                    ElevatedButton(
                                      onPressed: () {
                                        _showBookingDetails(context, booking);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF6418C3),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6418C3)),
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
                        const Text(
                          'Failed to load bookings',
                          style: TextStyle(
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
                          onPressed: _loadData,
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
          ),
        ],
      ),
    );
  }

  // Method to show booking details in a bottom sheet
  void _showBookingDetails(BuildContext context, GetHallBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isCompletedBooking(booking))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Add Review button in details view
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              // Navigate to review page with the appropriate ID
                              _navigateToReview(value, booking);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'property',
                                child: Row(
                                  children: [
                                    Icon(Icons.home, size: 18),
                                    SizedBox(width: 8),
                                    Text('For Property'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'hall',
                                child: Row(
                                  children: [
                                    Icon(Icons.meeting_room, size: 18),
                                    SizedBox(width: 8),
                                    Text('For Hall'),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(
                              Icons.rate_review,
                              color: Color(0xFF6418C3),
                              size: 20,
                            ),
                            tooltip: 'Add Review',
                          ),
                          const SizedBox(width: 8),
                          // Completed badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow('Property', booking.propertyName ?? 'Unknown'),
                _detailRow('Hall', booking.hallName ?? 'Unknown'),
                _detailRow('Date', formatDate(booking.date)),
                _detailRow('Time',
                    '${formatTime(booking.slotFromTime)} - ${formatTime(booking.slotToTime)}'),
                _detailRow('Status', booking.isPaid == 1 ? 'Paid' : 'Unpaid'),
                _detailRow('Booking ID', '#${booking.id}'),
              ],
            ),
          ),
        ),
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
