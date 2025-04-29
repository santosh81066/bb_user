import 'dart:convert';

import 'package:bb_user/Screens/review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Colors/coustcolors.dart';
import '../Providers/property.dart';
import '../Providers/subscribed_provider.dart';
import '../Providers/venues_provider.dart';
import '../models/get_properties_model.dart';
import '../utils/bbapi.dart';
import 'venudetails.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    GetData();
    ref.read(propertyprovider.notifier).getProperties();
    // Add these to fetch subscribed properties
    ref.read(propertyNotifierProvider.notifier).getproperty();
    ref.read(subscriptionProvider.notifier).fetchSubscriptions();
  }

  Future<void> GetData() async {
    final prefs = await SharedPreferences.getInstance();
    final extractData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    String sname = extractData['username'];
    setState(() {
      sUsername = sname;
    });
  }

  String sUsername = "Abc";
  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(propertyprovider);

    // Add this to watch subscribed properties
    final subscribedPropertyState =
        ref.watch(propertyNotifierProvider).data ?? [];
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
      backgroundColor: CoustColors.colrFill,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: const BoxDecoration(
                  color: Color(0xFF6418C3),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadiusDirectional.only(
                      bottomEnd: Radius.circular(25),
                      bottomStart: Radius.circular(25))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Welcome Back",
                            style: TextStyle(
                                color: CoustColors.colrEdtxt4, fontSize: 20)),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(sUsername,
                              style: const TextStyle(
                                  color: CoustColors.colrEdtxt4, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: IconButton(
                            icon: const Icon(Icons.notifications),
                            color: CoustColors.colrHighlightedText,
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed('/notification_settings');
                              print("Notification Clicked");
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 25.0),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: IconButton(
                            icon: const Icon(Icons.person),
                            color: CoustColors.colrHighlightedText,
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed('/profile_settings');
                              print("Person Clicked");
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, right: 20, top: 5),
                    child: Text('Quick Access',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QuickAccessCard(
                          icon: Icons.book,
                          label: 'My Bookings',
                        ),
                        QuickAccessCard(
                          icon: Icons.history,
                          label: 'Payment History',
                        ),
                        QuickAccessCard(
                          icon: Icons.account_balance_wallet,
                          label: 'Wallets',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add Subscribed Properties Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Newly added',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 20),
                              Container(
                                height: 240, // Adjust height as needed
                                child: filteredProperties.isNotEmpty
                                    ? ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: filteredProperties.length,
                                        itemBuilder: (context, index) {
                                          final property =
                                              filteredProperties[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                right: 16.0),
                                            child: PropertyHorizontalCard(
                                                property: property),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          'No venues',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20.0, right: 20, top: 5),
                    child: Text('Testimonial',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                              'Banquet Bookz: Event planning made easy! Love the intuitive design.',
                              textAlign: TextAlign.center),
                          SizedBox(height: 8),
                          Text('Kristin Watson',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                                5,
                                (index) => Icon(Icons.star,
                                    color: Colors.amber, size: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Recent Venue Reviews',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        review['imageAsset'],
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.error);
                                        },
                                      ),
                                      SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review['venueName'],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              review['heading'],
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic),
                                            ),
                                            Text(
                                              'User: ${review['userName']}',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.star,
                                                    color: Colors.orange,
                                                    size: 16),
                                                SizedBox(width: 5),
                                                Text('${review['rating']} / 5'),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              review['comment'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Details'),
                                          content: Text(
                                              'Details for ${review['venueName']} by ${review['userName']}'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text('View Details'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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

  // Sample review data
  final List<Map<String, dynamic>> reviews = [
    {
      'imageAsset': 'assets/hotel_image4.jpeg',
      'venueName': 'Swagath Grand',
      'userName': 'User name',
      'rating': 4.5,
      'comment':
          'Phasellus accumsan imperdiet tempor. Cras tincidunt, arcu nec eleifend porttitor, orci est vehicula.',
      'heading': 'Excellent Venue!'
    },
    {
      'imageAsset': 'assets/hotel_image5.jpeg',
      'venueName': 'Swagath Grand',
      'userName': 'User name',
      'rating': 4.5,
      'comment':
          'Phasellus accumsan imperdiet tempor. Cras tincidunt, arcu nec eleifend porttitor, orci est vehicula.',
      'heading': 'Amazing Service!'
    },
    {
      'imageAsset': 'assets/hotel_image6.jpeg',
      'venueName': 'Swagath Grand',
      'userName': 'User name',
      'rating': 4.5,
      'comment':
          'Phasellus accumsan imperdiet tempor. Cras tincidunt, arcu nec eleifend porttitor, orci est vehicula.',
      'heading': 'Memorable Experience'
    },
  ];
}

// Add this new widget for horizontal property cards
class PropertyHorizontalCard extends StatelessWidget {
  final Data property;

  const PropertyHorizontalCard({super.key, required this.property});

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
        width: 180,
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          border: Border.all(
            color: Colors.deepPurple.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property.coverPic != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  'https://www.gocodedesigners.com/banquetbookingz/${property.coverPic}',
                  width: 180,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 180,
                    height: 120,
                    color: Colors.grey[300],
                    child: Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.propertyName ?? 'No Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    property.address ?? 'No Address',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/venue_details',
                          arguments: {'property': property},
                        );
                      },
                      child: Text('View', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8),
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

// class Section extends StatelessWidget {
//   final String title;
//   final List<Item> items;
//
//   Section({required this.title, required this.items});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 20),
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             children: items.map((item) => ItemWidget(item: item)).toList(),
//           ),
//         ),
//       ],
//     );
//   }
// }

class Item {
  final String name;
  final String location;
  final String imagePath;

  Item(this.name, this.location, this.imagePath);
}

class ItemWidget extends StatelessWidget {
  final Item item;

  ItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Image.asset(
            item.imagePath,
            width: 80,
            height: 80,
            fit: BoxFit.fitWidth,
          ),
          SizedBox(height: 10),
          Text(item.name, style: TextStyle(fontSize: 16)),
          if (item.location.isNotEmpty)
            Text(item.location,
                style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

class QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;

  QuickAccessCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case "My Bookings":
            Navigator.of(context).pushNamed('/upcoming_booking');
            break;
          case "Payment History":
            Navigator.of(context).pushNamed('/payment_history');
            break;
          case "Wallets":
            break;
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.0),
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: CoustColors.colrHighlightedText),
            const SizedBox(height: 5.0),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
