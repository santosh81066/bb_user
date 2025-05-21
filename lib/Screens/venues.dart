import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../Colors/coustcolors.dart';
import '../Providers/subscribed_provider.dart';
import '../Providers/venues_provider.dart';
import '../models/get_properties_model.dart';

class Venuscreen extends ConsumerStatefulWidget {
  const Venuscreen({super.key});

  @override
  ConsumerState<Venuscreen> createState() => _ManageCalendarScreenState();
}

class _ManageCalendarScreenState extends ConsumerState<Venuscreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data with error handling
    try {
      ref.read(propertyNotifierProvider.notifier).getproperty();
      ref.read(subscriptionProvider.notifier).fetchSubscriptions();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(propertyNotifierProvider).data ?? [];
    final subscriptions = ref.watch(subscriptionProvider);

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
    final filteredProperties = propertyState.where((property) {
      // Filter by search query if one exists
      final matchesSearch = _searchQuery.isEmpty ||
          (property.propertyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (property.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Check if propertyId is not null and is contained in uniquePropertyIds
      return matchesSearch &&
          property.propertyId != null &&
          uniquePropertyIds.contains(property.propertyId);
    }).toList();

    // Sort properties
    filteredProperties.sort((a, b) {
      final aIndex = sortedPropertyIds.indexOf(a.propertyId!);
      final bIndex = sortedPropertyIds.indexOf(b.propertyId!);
      return aIndex.compareTo(bIndex);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6418C3),
          onRefresh: () async {
            try {
              await ref.read(propertyNotifierProvider.notifier).getproperty();
              await ref.read(subscriptionProvider.notifier).fetchSubscriptions();
            } catch (e) {
              debugPrint('Error refreshing data: $e');
            }
          },
          child: CustomScrollView(
            slivers: [
              // App Bar with Search
              SliverToBoxAdapter(
                child: _buildAppBarWithSearch(),

              ),

              // Main Content
              filteredProperties.isNotEmpty
                  ? SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: PropertyCard(
                                property: filteredProperties[index],
                                name: filteredProperties[index].propertyName ?? 'No Name',
                                location: filteredProperties[index].location ?? 'No Address',
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredProperties.length,
                    ),
                  ),
                ),
              )
                  : SliverFillRemaining(
                child: _buildEmptyState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarWithSearch() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6418C3), Color(0xFF8547D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            offset: Offset(0, 3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                "Venues",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search venues...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color(0xFF6418C3).withOpacity(0.7),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.house_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "You may need to add the following dependencies to your pubspec.yaml:\n• google_fonts\n• flutter_staggered_animations",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'No venues found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Subscribe to venues to see them here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Data property;

  const PropertyCard({
    super.key,
    required this.property,
    required String name,
    required String location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                '/venue_details',
                arguments: {'property': property},
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'property_image_${property.propertyId}',
                      child: _buildPropertyImage(),
                    ),
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6418C3).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "4.8",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.propertyName ?? 'No Name',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFF6418C3),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.address ?? 'No Address',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPropertyFeatures(),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/venue_details',
                            arguments: {'property': property},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF6418C3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(
                          "View Details",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyImage() {
    final imageUrl = property.coverPic != null
        ? 'http://www.gocodedesigners.com/banquetbookingz/${property.coverPic}'
        : null;

    // For debugging the image URL
    // debugPrint('Image URL: $imageUrl');

    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: imageUrl != null
          ? Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6418C3)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Print error for debugging
          debugPrint('Error loading image: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  "Image not available",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      )
          : Center(
        child: Icon(
          Icons.image,
          color: Colors.grey[400],
          size: 40,
        ),
      ),
    );
  }

  Widget _buildPropertyFeatures() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureItem(Icons.group, "Capacity"),
        _buildFeatureItem(Icons.local_parking, "Parking"),
        _buildFeatureItem(Icons.restaurant, "Food"),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6418C3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6418C3).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF6418C3),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}