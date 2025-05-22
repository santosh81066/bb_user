import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Colors/coustcolors.dart';
import '../Providers/get_hall_booking_provider.dart';
import '../Providers/hall_booking_provider.dart';
import '../Providers/venues_provider.dart';
import '../models/get_hall_booking.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class ManageBookingScreen extends ConsumerStatefulWidget {
  const ManageBookingScreen({super.key});

  @override
  ConsumerState<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends ConsumerState<ManageBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Load data when screen initializes
    Future.microtask(() async {
      await _loadData();
    });
  }

  // Explicit method to load all required data
  Future<void> _loadData() async {
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
    if (time.isEmpty || !time.contains(':')) return 'Invalid Time';

    final timeParts = time.split(':');
    if (timeParts.length < 2) return 'Invalid Time';

    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$formattedHour:$minute $period';
  }

  // Check if a booking is upcoming (future date)
  bool isUpcomingBooking(GetHallBooking booking) {
    final today = DateTime.now();
    final bookingDate = DateTime.parse(booking.date);
    return bookingDate.isAfter(today);
  }

  // Check if a booking is completed (past date)
  bool isCompletedBooking(GetHallBooking booking) {
    if (booking.slotToTime.isEmpty || !booking.slotToTime.contains(':'))
      return false;

    final endParts = booking.slotToTime.split(':');
    if (endParts.length < 2) return false;

    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMinute = int.tryParse(endParts[1]) ?? 0;

    final bookingDate = DateTime.tryParse(booking.date) ?? DateTime.now();
    final endDateTime = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      endHour,
      endMinute,
    );

    return endDateTime.isBefore(DateTime.now());
  }

// First, let's add a method to identify canceled bookings
  bool isCanceledBooking(GetHallBooking booking) {
    // Based on your existing code, it appears 'cl' represents canceled bookings
    return booking.isPaid == 'cl';
  }

// Then update the filterBookings method to handle canceled bookings
  List<GetHallBooking> filterBookings(List<GetHallBooking> bookings, int tabIndex) {
    List<GetHallBooking> filteredList;

    switch (tabIndex) {
      case 0: // All
        filteredList = bookings.toList(); // Show all bookings, including cancelled
        break;
      case 1: // Upcoming
        filteredList = bookings.where((booking) => isUpcomingBooking(booking) && !isCanceledBooking(booking)).toList();
        break;
      case 2: // Completed
        filteredList = bookings.where((booking) => isCompletedBooking(booking) && !isCanceledBooking(booking)).toList();
        break;
      case 3: // Cancelled
        filteredList = bookings.where((booking) => isCanceledBooking(booking)).toList();
        break;
      default:
        filteredList = bookings.toList();
    }

    // Apply search filter if search query exists
    if (searchQuery.isNotEmpty) {
      filteredList = filteredList.where((booking) {
        final hallNameMatch = booking.hallName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
        final propertyMatch = booking.propertyName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
        final dateMatch = booking.date.contains(searchQuery);
        return hallNameMatch || propertyMatch || dateMatch;
      }).toList();
    }

    // Sort bookings by date and time in descending order
    filteredList.sort((a, b) {
      try {
        final dateA = DateTime.tryParse(a.date);
        final dateB = DateTime.tryParse(b.date);

        if (dateA == null || dateB == null) return 0;

        // If dates are the same, sort by time
        if (dateA.year == dateB.year && dateA.month == dateB.month && dateA.day == dateB.day) {
          if (a.slotFromTime.isEmpty || b.slotFromTime.isEmpty) return 0;

          final timeA = a.slotFromTime.split(':');
          final timeB = b.slotFromTime.split(':');

          if (timeA.length < 2 || timeB.length < 2) return 0;

          final hourA = int.tryParse(timeA[0]) ?? 0;
          final minuteA = int.tryParse(timeA[1]) ?? 0;
          final hourB = int.tryParse(timeB[0]) ?? 0;
          final minuteB = int.tryParse(timeB[1]) ?? 0;

          if (hourA != hourB) return hourB.compareTo(hourA);
          return minuteB.compareTo(minuteA);
        }

        return dateB.compareTo(dateA);
      } catch (e) {
        debugPrint('Sort error: $e');
        return 0;
      }
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
      } else {
        // Show error message if property not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property information not found'),
            behavior: SnackBarBehavior.floating,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsyncValue = ref.watch(gethallBookingsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6418C3), Color(0xFF7A30E0)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                    Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "My Bookings",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () {
                              // Notification action
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400]),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search bookings...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                            ),
                          ),
                          if (searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  searchQuery = '';
                                  searchController.clear();
                                });
                              },
                              child: Icon(Icons.close, color: Colors.grey[400]),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child:TabBar(
                controller: _tabController,
                isScrollable: false, // Set to false for equal width tabs
                labelPadding: EdgeInsets.zero, // Remove padding to maximize space
                indicatorColor: Colors.purple, // Based on your screenshot
                labelColor: Colors.purple, // Active tab color
                unselectedLabelColor: Colors.grey, // Inactive tab color
                tabs: [
                  buildEqualTab(context, "All", Icons.calendar_month, 0),
                  buildEqualTab(context, "Upcoming", Icons.upcoming, 1),
                  buildEqualTab(context, "Completed", Icons.check_circle_outline, 2),
                  buildEqualTab(context, "Cancelled", Icons.cancel_outlined, 3),
                ],
              )
            ),

            // Bookings List with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                key: _refreshKey,
                onRefresh: _loadData,
                color: Color(0xFF6418C3),
                child: bookingsAsyncValue.when(
                  data: (bookings) {
                    final filteredBookings = filterBookings(
                        bookings, _tabController.index);

                    if (filteredBookings.isEmpty) {
                      return _buildEmptyState(_tabController.index);
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = filteredBookings[index];
                        final isCompleted = isCompletedBooking(booking);

                        return _buildBookingCard(booking, isCompleted);
                      },
                    );
                  },
                  loading: () =>
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6418C3)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading your bookings...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  error: (error, stackTrace) => _buildErrorState(error),
                ),
              ),
            ),
          ],
        ),
      ),
     /* floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create booking screen
          Navigator.of(context).pushNamed('/venue_details');
        },
        backgroundColor: Color(0xFF6418C3),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('New Booking', style: TextStyle(color: Colors.white)),
      ),*/
    );
  }



  Widget buildEqualTab(BuildContext context, String text, IconData icon, int index) {
    final isSelected = _tabController.index == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Tab(
      height: 50, // Fixed height for all tabs
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 16 : 18,
          ),
          SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String message;
    IconData iconData;
    String actionText;

    switch (tabIndex) {
      case 1:
        message = 'No upcoming bookings';
        iconData = Icons.calendar_today_outlined;
        actionText = 'Book a venue now';
        break;
      case 2:
        message = 'No completed bookings yet';
        iconData = Icons.event_available;
        actionText = 'View your booking history';
        break;
      case 3:
        message = 'No Cancelled bookings yet';
        iconData = Icons.event_busy_outlined;
        actionText = 'View your booking history';
        break;
      default:
        message = 'No bookings found';
        iconData = Icons.calendar_month;
        actionText = 'Create your first booking';
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.3,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF6418C3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 48,
                    color: Color(0xFF6418C3),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pull down to refresh or tap the button below',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (tabIndex == 0 || tabIndex == 1) {
                      // Navigate to booking creation
                      Navigator.of(context).pushNamed('/create-booking');
                    } else {
                      // Refresh to check for completed bookings
                      _refreshKey.currentState?.show();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6418C3),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We couldn\'t load your bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6418C3),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(GetHallBooking booking, bool isCompleted) {
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isCanceledBooking(booking)) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Canceled';
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (isUpcomingBooking(booking)) {
      statusColor = Colors.blue;
      statusIcon = Icons.upcoming;
      statusText = 'Upcoming';
    } else {
      statusColor = Colors.amber;
      statusIcon = Icons.pending;
      statusText = 'Active';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Booking header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCanceledBooking(booking)
                    ? [Colors.red.withOpacity(0.8), Colors.red.shade700.withOpacity(0.8)]
                    : [Color(0xFF6418C3).withOpacity(0.8), Color(0xFF7A30E0).withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.propertyName ?? 'Unknown Property',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hall info
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      color: isCanceledBooking(booking) ? Colors.red : Color(0xFF6418C3),
                      size: 18,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Hall:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.hallName ?? 'Unknown Hall',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Date info
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: isCanceledBooking(booking) ? Colors.red : Color(0xFF6418C3),
                      size: 18,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      formatDate(booking.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Time info
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: isCanceledBooking(booking) ? Colors.red : Color(0xFF6418C3),
                      size: 18,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Time:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${formatTime(booking.slotFromTime)} - ${formatTime(booking.slotToTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),

                // Actions - different actions based on booking status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isCompleted && !isCanceledBooking(booking))
                      TextButton.icon(
                        onPressed: () {
                          // Show cancel confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Cancel Booking'),
                              content: Text('Are you sure you want to cancel this booking?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('No'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Close the dialog first
                                    Navigator.pop(context);

                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Text('Cancelling booking...'),
                                          ],
                                        ),
                                        duration: Duration(seconds: 60), // Long duration as placeholder
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );

                                    try {
                                      // Call the cancelBooking method from provider
                                      final success = await ref.read(hallBookingProvider.notifier).cancelBooking(
                                        bookingId: booking.id,
                                      );

                                      // Hide the loading indicator
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                      if (success) {
                                        // Show success message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Booking cancelled successfully'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.green,
                                          ),
                                        );

                                        // Refresh booking list to reflect changes
                                        await _loadData();
                                      } else {
                                        // Show error message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to cancel booking. Please try again.'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Hide the loading indicator
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                      // Show error message
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Yes, Cancel',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.cancel_outlined, color: Colors.red),
                        label: Text('Cancel', style: TextStyle(color: Colors.red)),
                      )
                    else if (isCompleted && !isCanceledBooking(booking))
                      TextButton.icon(
                        onPressed: () {
                          // Show review options
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Add Review',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ListTile(
                                    leading: Icon(Icons.home, color: Color(0xFF6418C3)),
                                    title: Text('Review Property'),
                                    subtitle: Text(booking.propertyName ?? 'Unknown Property'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _navigateToReview('property', booking);
                                    },
                                  ),
                                  Divider(),
                                  ListTile(
                                    leading: Icon(Icons.meeting_room, color: Color(0xFF6418C3)),
                                    title: Text('Review Hall'),
                                    subtitle: Text(booking.hallName ?? 'Unknown Hall'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _navigateToReview('hall', booking);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.rate_review_outlined, color: Color(0xFF6418C3)),
                        label: Text('Review', style: TextStyle(color: Color(0xFF6418C3))),
                      )
                    else if (isCanceledBooking(booking))
                        Text(
                          'Booking Canceled',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                    ElevatedButton.icon(
                      onPressed: () => _showBookingDetails(context, booking),
                      icon: Icon(Icons.visibility, color: Colors.white),
                      label: Text('View Details', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCanceledBooking(booking) ? Colors.red : Color(0xFF6418C3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
// Method to show booking details in a bottom sheet
  // Enhanced method to show booking details in a bottom sheet
  void _showBookingDetails(BuildContext context, GetHallBooking booking) {
    String _getBookingStatusFromIsPaid(String isPaid) {
      switch (isPaid) {
        case 'b':
          return 'Blocked';
        case 'c':
          return 'Confirmed';
        case '0':
          return 'Available';
        case '1':
          return 'Confirmed & Paid';
        case 'cl':
          return 'Canceled';
        default:
          return 'Unknown';
      }
    }

    Color _getStatusColor(String isPaid) {
      switch (isPaid) {
        case 'b':
          return Colors.orange;
        case 'c':
          return Colors.blue;
        case '0':
          return Colors.grey;
        case '1':
          return Colors.green;
        case 'cl':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    IconData _getStatusIcon(String isPaid) {
      switch (isPaid) {
        case 'b':
          return Icons.block;
        case 'c':
          return Icons.check_circle_outline;
        case '0':
          return Icons.radio_button_unchecked;
        case '1':
          return Icons.check_circle;
        case 'cl':
          return Icons.cancel;
        default:
          return Icons.help_outline;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header with gradient background
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCanceledBooking(booking)
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [Color(0xFF6418C3), Color(0xFF7A30E0)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isCanceledBooking(booking) ? Colors.red : Color(0xFF6418C3)).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ID: #${booking.id}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(booking.isPaid),
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              _getBookingStatusFromIsPaid(booking.isPaid),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Venue Information Card
                    _buildDetailCard(
                      title: 'Venue Information',
                      icon: Icons.location_on,
                      children: [
                        _buildDetailItem(
                          icon: Icons.business,
                          label: 'Property',
                          value: booking.propertyName ?? 'Unknown Property',
                          iconColor: Color(0xFF6418C3),
                        ),
                        Divider(height: 20, color: Colors.grey[200]),
                        _buildDetailItem(
                          icon: Icons.meeting_room,
                          label: 'Hall',
                          value: booking.hallName ?? 'Unknown Hall',
                          iconColor: Color(0xFF6418C3),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Date & Time Information Card
                    _buildDetailCard(
                      title: 'Schedule Information',
                      icon: Icons.schedule,
                      children: [
                        _buildDetailItem(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: formatDate(booking.date),
                          iconColor: Color(0xFF6418C3),
                        ),
                        Divider(height: 20, color: Colors.grey[200]),
                        _buildDetailItem(
                          icon: Icons.access_time,
                          label: 'Time Slot',
                          value: '${formatTime(booking.slotFromTime)} - ${formatTime(booking.slotToTime)}',
                          iconColor: Color(0xFF6418C3),
                        ),
                        Divider(height: 20, color: Colors.grey[200]),
                        _buildDetailItem(
                          icon: Icons.timelapse,
                          label: 'Duration',
                          value: _calculateDuration(booking.slotFromTime, booking.slotToTime),
                          iconColor: Color(0xFF6418C3),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Booking Status Card
                    _buildDetailCard(
                      title: 'Booking Status',
                      icon: _getStatusIcon(booking.isPaid),
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.isPaid).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(booking.isPaid).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(booking.isPaid),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getStatusIcon(booking.isPaid),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getBookingStatusFromIsPaid(booking.isPaid),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(booking.isPaid),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      _getStatusDescription(booking.isPaid),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Action Buttons
                    if (isCompletedBooking(booking) && !isCanceledBooking(booking))
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Show review options
                            showModalBottomSheet(
                              context: context,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => Container(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Add Your Review',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    _buildReviewOption(
                                      icon: Icons.home,
                                      title: 'Review Property',
                                      subtitle: booking.propertyName ?? 'Unknown Property',
                                      onTap: () {
                                        Navigator.pop(context);
                                        _navigateToReview('property', booking);
                                      },
                                    ),
                                    SizedBox(height: 12),
                                    _buildReviewOption(
                                      icon: Icons.meeting_room,
                                      title: 'Review Hall',
                                      subtitle: booking.hallName ?? 'Unknown Hall',
                                      onTap: () {
                                        Navigator.pop(context);
                                        _navigateToReview('hall', booking);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.rate_review, color: Colors.white),
                          label: Text(
                            'Add Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6418C3),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper method to build detail cards
  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF6418C3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF6418C3),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

// Helper method to build detail items
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

// Helper method to build review options
  Widget _buildReviewOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF6418C3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Color(0xFF6418C3),
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

// Helper method to calculate duration
  String _calculateDuration(String fromTime, String toTime) {
    try {
      if (fromTime.isEmpty || toTime.isEmpty || !fromTime.contains(':') || !toTime.contains(':'))
        return 'N/A';

      final fromParts = fromTime.split(':');
      final toParts = toTime.split(':');

      if (fromParts.length < 2 || toParts.length < 2) return 'N/A';

      final fromHour = int.tryParse(fromParts[0]) ?? 0;
      final fromMinute = int.tryParse(fromParts[1]) ?? 0;
      final toHour = int.tryParse(toParts[0]) ?? 0;
      final toMinute = int.tryParse(toParts[1]) ?? 0;

      final fromTotalMinutes = fromHour * 60 + fromMinute;
      final toTotalMinutes = toHour * 60 + toMinute;

      final durationMinutes = toTotalMinutes - fromTotalMinutes;
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;

      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}m';
      }
    } catch (e) {
      return 'N/A';
    }
  }

// Helper method to get status description
  String _getStatusDescription(String isPaid) {
    switch (isPaid) {
      case 'b':
        return 'This booking slot is temporarily blocked';
      case 'c':
        return 'Your booking has been confirmed';
      case '0':
        return 'Booking slot is available for reservation';
      case '1':
        return 'Booking confirmed and payment completed';
      case 'cl':
        return 'This booking has been cancelled';
      default:
        return 'Status information not available';
    }
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