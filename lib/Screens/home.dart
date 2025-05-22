import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../Colors/coustcolors.dart';
import '../Providers/get_review_provider.dart';
import '../Providers/subscribed_provider.dart';
import '../Providers/venues_provider.dart';
import '../models/get_properties_model.dart';
import '../models/get_review_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String userName = "Guest";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getData();
    ref.read(propertyNotifierProvider.notifier).getproperty();
    ref.read(subscriptionProvider.notifier).fetchSubscriptions();
    ref.read(reviewsProvider.notifier).fetchReviews(Hall());
  }

  Future<void> getData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final extractData =
      json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      setState(() {
        userName = extractData['username'] ?? "Guest";
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscribedPropertyState = ref.watch(propertyNotifierProvider).data ?? [];
    final subscriptions = ref.watch(subscriptionProvider);
    final reviewsState = ref.watch(reviewsProvider);

    // Get unique property IDs from subscriptions, sorted by start_time
    final Set<int> uniquePropertyIds = {};
    final sortedPropertyIds = <int>[];

    for (var subscription in subscriptions) {
      if (!uniquePropertyIds.contains(subscription.Id)) {
        uniquePropertyIds.add(subscription.Id);
        sortedPropertyIds.add(subscription.Id);
      }
    }

    // Filter properties that match the IDs from subscriptions
    final filteredProperties = subscribedPropertyState.where((property) {
      return property.propertyId != null &&
          uniquePropertyIds.contains(property.propertyId);
    }).toList();

    // Sort properties based on subscription order
    filteredProperties.sort((a, b) {
      final aIndex = sortedPropertyIds.indexOf(a.propertyId!);
      final bIndex = sortedPropertyIds.indexOf(b.propertyId!);
      return aIndex.compareTo(bIndex);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await getData();
            ref.read(propertyNotifierProvider.notifier).getproperty();
            ref.read(subscriptionProvider.notifier).fetchSubscriptions();
            ref.read(reviewsProvider.notifier).fetchReviews(Hall());
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: buildAppBar(),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: buildSearchBar(),
              ),

              // Quick Access
              SliverToBoxAdapter(
                child: buildQuickAccess(),
              ),

              // Newly Added Properties
              SliverToBoxAdapter(
                child: buildNewlyAddedProperties(filteredProperties),
              ),

              // Recent Reviews
              SliverToBoxAdapter(
                child:buildRecentReviews(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppBar() {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Color(0xFF6418C3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: CoustColors.colrFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: isLoading
                        ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 45,
                        width: 45,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : "G",
                      style: GoogleFonts.poppins(
                        color: CoustColors.colrHighlightedText,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back",
                    style: GoogleFonts.poppins(
                      color: CoustColors.colrFill,
                      fontSize: 13,
                    ),
                  ),
                  isLoading
                      ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 18,
                      width: 100,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    userName,
                    style: GoogleFonts.poppins(
                      color: CoustColors.colrFill,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/notification_settings');
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 28,color: CoustColors.colrFill,),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '3',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Search for venues, halls...",
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[400],
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CoustColors.colrHighlightedText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: CoustColors.colrHighlightedText,
                size: 20,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Access",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EnhancedQuickAccessCard(
                icon: Icons.calendar_today_rounded,
                label: 'My Bookings',
                color: const Color(0xFF6418C3),
                route: '/manage_booking',
              ),
              EnhancedQuickAccessCard(
                icon: Icons.receipt_long_rounded,
                label: 'Payment History',
                color: const Color(0xFF00BA88),
                route: '/payment_history',
              ),
              EnhancedQuickAccessCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Wallets',
                color: const Color(0xFFF4A732),
                route: '/wallet',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildNewlyAddedProperties(List<dynamic> properties) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Newly Added",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all properties
                },
                child: Text(
                  "View All",
                  style: GoogleFonts.poppins(
                    color: CoustColors.colrHighlightedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          properties.isNotEmpty
              ? SizedBox(
            height: 200, // Reduced from 220 to 200 to match our changes
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return EnhancedPropertyCard(property: property);
              },
            ),
          )
              : Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.house_rounded,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No venues available yet",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to explore page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CoustColors.colrHighlightedText,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Explore Venues",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecentReviews(WidgetRef ref) {
    // Use ref.watch to watch the provider
    final reviewsState = ref.watch(reviewsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Reviews",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all reviews or refresh
                  // Option 1: Refresh reviews
                  ref.refresh(reviewsProvider);

                  // Option 2: If using the refresh provider
                  // ref.read(reviewsRefreshProvider.notifier).state++;
                },
                child: Text(
                  "View All",
                  style: GoogleFonts.poppins(
                    color: CoustColors.colrHighlightedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Handle different provider types
          reviewsState.when(
            loading: () => const ReviewLoadingSkeleton(),
            error: (error, stackTrace) {
              print("MANJUNADH$error");
              return Column(
                children: [
                  ReviewErrorWidget(error: error.toString()),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => ref.refresh(reviewsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              );
            },
            data: (reviews) {
              print("SANTOSH$reviews");
              if (reviews.isEmpty) {
                return const EmptyReviewsWidget();
              }

              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length > 3 ? 3 : reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return EnhancedReviewCard(review: review);
                    },
                  ),
                  // Add refresh button if needed
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => ref.refresh(reviewsProvider),
                    child: const Text('Refresh Reviews'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class EnhancedQuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const EnhancedQuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(route);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Update this widget to fix the overflow issue
class EnhancedPropertyCard extends StatelessWidget {
  final dynamic property;

  const EnhancedPropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/venue_details',
          arguments: {'property': property},
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                children: [
                  property.coverPic != null
                      ? Image.network(
                    'http://www.gocodedesigners.com/banquetbookingz/${property.coverPic}',
                    width: 160,
                    height: 100, // Reduced height from 120 to 100
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 160,
                      height: 100, // Reduced height from 120 to 100
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  )
                      : Container(
                    width: 160,
                    height: 100, // Reduced height from 120 to 100
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CoustColors.colrHighlightedText.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "4.5",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10), // Reduced padding from 12 to 10
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.propertyName ?? 'No Name',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // Reduced font size from 14 to 13
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Reduced spacing from 4 to 2
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[400],
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.address ?? 'No Address',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced spacing from 8 to 6
                  SizedBox(
                    height: 30, // Fixed height for button
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/venue_details',
                          arguments: {'property': property},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CoustColors.colrHighlightedText,
                        minimumSize: const Size(double.infinity, 30),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "View Details",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedReviewCard extends StatelessWidget {
  final dynamic review;

  const EnhancedReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final venueName = review.propertyName ?? review.hallName ?? 'Unknown Venue';
    final venueType = review.propertyId != null ? 'Property' : 'Hall';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: review.propertyId != null
                      ? const Color(0xFF6418C3).withOpacity(0.1)
                      : const Color(0xFF00BA88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  review.propertyId != null ? Icons.apartment_rounded : Icons.meeting_room_rounded,
                  color: review.propertyId != null ? const Color(0xFF6418C3) : const Color(0xFF00BA88),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "$venueType",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                            (i) => Icon(
                          i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.reviewText,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "User ID: ${review.userId}",
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Details',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Venue: $venueName',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Type: $venueType',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Rating: ${review.rating}/5',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(
                                    5,
                                        (i) => Icon(
                                      i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Review:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              review.reviewText,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CoustColors.colrHighlightedText,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View Details",
                  style: GoogleFonts.poppins(
                    color: CoustColors.colrHighlightedText,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReviewLoadingSkeleton extends StatelessWidget {
  const ReviewLoadingSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: List.generate(
          3,
              (index) => Container(
            margin: const EdgeInsets.only(bottom: 15),
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}

class ReviewErrorWidget extends StatelessWidget {
  final String error;

  const ReviewErrorWidget({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            'Error loading reviews',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            error,
            style: GoogleFonts.poppins(
              color: Colors.red[700],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class EmptyReviewsWidget extends StatelessWidget {
  const EmptyReviewsWidget({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 45,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 10),
          Text(
            'No reviews available yet',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              // Navigate to add review
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CoustColors.colrHighlightedText,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Write a Review",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}