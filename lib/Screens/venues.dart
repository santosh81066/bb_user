import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(propertyNotifierProvider.notifier).getproperty();
    ref.read(subscriptionProvider.notifier).fetchSubscriptions();
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
      // Check if propertyId is not null and is contained in uniquePropertyIds
      return property.propertyId != null &&
          uniquePropertyIds.contains(
              property.propertyId); // Assuming propertyId is now an int
    }).toList();

// And your sorting function:
    filteredProperties.sort((a, b) {
      final aIndex = sortedPropertyIds.indexOf(a.propertyId!);
      final bIndex = sortedPropertyIds.indexOf(b.propertyId!);
      return aIndex.compareTo(bIndex);
    });
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 130,
                  // ignore: unnecessary_const
                  decoration: const BoxDecoration(
                      color: Color(0xFF6418C3),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadiusDirectional.only(
                          bottomEnd: Radius.circular(25),
                          bottomStart: Radius.circular(25))),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 30.0, left: 15),
                    child: Text("Venues",
                        style: TextStyle(
                            color: CoustColors.colrEdtxt4, fontSize: 20)),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: 16.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              child: filteredProperties.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredProperties.length,
                      itemBuilder: (context, index) {
                        final property = filteredProperties[index];
                        return Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50],
                            border: Border.all(
                              color: Colors.deepPurple.shade200,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PropertyCard(
                            property: property,
                            name: property.propertyName ?? 'No Name',
                            location: property.address ?? 'No Address',
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No properties available',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Data property;

  const PropertyCard(
      {super.key,
      required this.property,
      required String name,
      required String location});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        if (property.coverPic != null)
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.deepPurple, // border color
                  width: 2, // border width
                ),
                borderRadius:
                    BorderRadius.circular(8), // optional: rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://www.gocodedesigners.com/banquetbookingz/${property.coverPic}',
                  width: 300,
                  height: 200,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text("Image not found")),
                ),
              ),
            ),
          ),
        ListTile(
          title: Text(
            property.propertyName ?? 'No Name',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            property.address ?? 'No Address',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).pushNamed(
              '/venue_details',
              arguments: {'property': property},
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
