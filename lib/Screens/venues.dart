import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../Colors/coustcolors.dart';
import '../Providers/property.dart';
import '../models/venues_listmodel.dart';
import '../utils/bbapi.dart';
import 'venudetails.dart';

// ignore: must_be_immutable
class Venuscreen extends ConsumerStatefulWidget {
  const Venuscreen({super.key});

  @override
  ConsumerState<Venuscreen> createState() => _VenuscreenState();
}

class _VenuscreenState extends ConsumerState<Venuscreen> {
  final List<VenuesListmodel> _items = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 1; i++) {
      _items.add(VenuesListmodel("Swagath Grand", 'images/flutter.jpg', 3.5, 84,
          'Bachupally, Hyderabad\nAug 25, 2023'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyState = ref.watch(propertyprovider);
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      //bottomNavigationBar: CoustNavigation(nav_index: 1,),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 90,
                  // ignore: unnecessary_const
                  decoration: const BoxDecoration(
                      color: Color(0xFF6418C3),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadiusDirectional.only(
                          bottomEnd: Radius.circular(25),
                          bottomStart: Radius.circular(25))),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 20.0, left: 15),
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
          propertyState.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (properties) {
                return Expanded(
                  child: ListView.builder(
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        // final item = _items[index];
                        final property = properties[index];
                        LatLng latLng =
                            PropertyLocationConverter.parseLocationString(
                                '${property.location}');
                        String imageurl =
                            '${Bbapi.baseUrl2}' + '${property.propertyPic}';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Card(
                            elevation: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, bottom: 16, right: 16, left: 25),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Image.network(
                                        imageurl,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.fill,
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 7.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Swagath Grand banquet hall",
                                                style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star,
                                                      color: Colors.amber,
                                                      size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      '${property.averageRating} (${property.reviewCount})',
                                                      style: const TextStyle(
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          fontSize: 16,
                                                          color: Colors.black)),
                                                ],
                                              ),
                                              Text(
                                                '${property.address1} ' +
                                                    '${property.address2}\n'
                                                        '${property.pincode}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      CoustColors.colrSubText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        //Copywith
                                        // Handle button press
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VenuDetailsScreen(
                                                    property: property),
                                          ),
                                        );
                                        // Navigator.of(context).pushNamed('/venue_details');
                                        //print('Button pressed for ${item.heading}         ${_items[index]}');
                                      },
                                      child: const Text('View Details'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                );
              }),
        ],
      ),
    );
  }
}
