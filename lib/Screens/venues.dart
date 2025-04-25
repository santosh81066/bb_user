import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Colors/coustcolors.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(propertyNotifierProvider).data ?? [];

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
              child: propertyState.isNotEmpty
                  ? ListView.builder(
                      itemCount: propertyState.length,
                      itemBuilder: (context, index) {
                        final property = propertyState[index];
                        return Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50], // background color
                            border: Border.all(
                              color: Colors.deepPurple.shade200, // border color
                              width: 1, // border width
                            ),
                            borderRadius:
                                BorderRadius.circular(12), // rounded corners
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
