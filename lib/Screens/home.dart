import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Colors/coustcolors.dart';
import '../Providers/property.dart';
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
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Container(
              width: double.infinity,
              height: 90,
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
                          Section(
                            title: 'Newly added',
                            items: [
                              Item('BerkahMaju', 'Kiel', 'assets/new_image.jpg',), 
                              Item('CahayaBerkat', 'Sterlitamak', 'assets/hotel_image.jpeg'),
                              Item('MutiaraAbadi', 'Chelyabinsk', 'assets/hotel_image2.jpeg'),
                            ],
                          ),
                          SizedBox(height: 20),
                          Section(
                            title: 'Recently viewed',
                            items: [
                              Item('Swagath Grand Banquet Hall', '', 'assets/hotel_image3.jpeg'),
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
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
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
                  
                  //const Padding(
                  //   padding: EdgeInsets.only(left: 20.0, right: 20, top: 5),
                  //   child: Text('Recent Venue Reviews',
                  //       style: TextStyle(
                  //           fontSize: 18, fontWeight: FontWeight.bold)),
                  // ),
                  // Padding(
                  //   padding: EdgeInsets.all(20),
                  //   child: propertyState.when(
                  //       loading: () =>
                  //           Center(child: CircularProgressIndicator()),
                  //       error: (error, stack) =>
                  //           Center(child: Text('Error: $error')),
                  //       data: (properties) {
                  //         return ListView.builder(
                  //             physics: NeverScrollableScrollPhysics(),
                  //             shrinkWrap: true,
                  //             itemCount: properties.length,
                  //             itemBuilder: (context, index) {
                  //               final property = properties[index];
                  //               LatLng latLng = PropertyLocationConverter
                  //                   .parseLocationString(
                  //                       '${property.location}');
                  //               String imageurl = '${Bbapi.baseUrl}' +
                  //                   '${property.propertyPic}';
                  //               return Padding(
                  //                 padding: const EdgeInsets.symmetric(
                  //                     horizontal: 8.0, vertical: 4.0),
                  //                 child: Card(
                  //                   elevation: 4.0,
                  //                   child: Padding(
                  //                     padding: const EdgeInsets.only(
                  //                         top: 16.0,
                  //                         bottom: 16,
                  //                         right: 16,
                  //                         left: 25),
                  //                     child: Column(
                  //                       children: [
                  //                         Row(
                  //                           children: [
                  //                             Container(),
                  //                             Image.network(
                  //                               imageurl,
                  //                               width: 50,
                  //                               height: 50,
                  //                               fit: BoxFit.fill,
                  //                             ),
                  //                             SizedBox(width: 16),
                  //                             Expanded(
                  //                               child: Padding(
                  //                                 padding:
                  //                                     const EdgeInsets.only(
                  //                                         left: 7.0),
                  //                                 child: Column(
                  //                                   crossAxisAlignment:
                  //                                       CrossAxisAlignment
                  //                                           .start,
                  //                                   children: [
                  //                                     Text(
                  //                                       "item.heading",
                  //                                       style: const TextStyle(
                  //                                           fontSize: 24,
                  //                                           fontWeight:
                  //                                               FontWeight.bold,
                  //                                           color:
                  //                                               Colors.black),
                  //                                     ),
                  //                                     Row(
                  //                                       children: [
                  //                                         const Icon(Icons.star,
                  //                                             color:
                  //                                                 Colors.amber,
                  //                                             size: 16),
                  //                                         const SizedBox(
                  //                                             width: 4),
                  //                                         Text(
                  //                                             '${property.averageRating} (${property.reviewCount})',
                  //                                             style: const TextStyle(
                  //                                                 fontStyle:
                  //                                                     FontStyle
                  //                                                         .italic,
                  //                                                 fontSize: 16,
                  //                                                 color: Colors
                  //                                                     .black)),
                  //                                       ],
                  //                                     ),
                  //                                     Text(
                  //                                       '${property.address1} ' +
                  //                                           '${property.address2}\n'
                  //                                               '${property.pincode}',
                  //                                       style: const TextStyle(
                  //                                         fontSize: 16,
                  //                                         color: CoustColors
                  //                                             .colrSubText,
                  //                                       ),
                  //                                     ),
                  //                                   ],
                  //                                 ),
                  //                               ),
                  //                             ),
                  //                           ],
                  //                         ),
                  //                         SizedBox(
                  //                           width: double.infinity,
                  //                           child: ElevatedButton(
                  //                             onPressed: () async {
                  //                               Navigator.push(
                  //                                   context,
                  //                                   MaterialPageRoute(
                  //                                       builder: (context) =>
                  //                                           VenuDetailsScreen(
                  //                                               property:
                  //                                                   property)));
                  //                             },
                  //                             child: const Text('View Details'),
                  //                           ),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   ),
                  //                 ),
                  //               );
                  //             });
                  //       }),
                  // )
                    Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Recent Venue Reviews',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true, // Ensures ListView takes only necessary space
                    physics: NeverScrollableScrollPhysics(), // Prevents scrolling inside ListView
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  review['imageAsset'], // Use asset image
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.error); // Fallback for image error
                                  },
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['venueName'], // Venue name
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        review['heading'], // Review heading
                                        style: TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                      Text(
                                        'User: ${review['userName']}', // User name
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.orange, size: 16),
                                          SizedBox(width: 5),
                                          Text('${review['rating']} / 5'), // Rating
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        review['comment'], // Review comment
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
                                // Navigate to details or show more information
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Details'),
                                    content: Text('Details for ${review['venueName']} by ${review['userName']}'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
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
}
 // Sample review data
  final List<Map<String, dynamic>> reviews = [
    {
      'imageAsset': 'assets/hotel_image4.jpeg',
      'venueName': 'Swagath Grand',
      'userName': 'User name',
      'rating': 4.5,
      'comment': 'Phasellus accumsan imperdiet tempor. Cras tincidunt, arcu nec eleifend porttitor, orci est vehicula.',
      'heading': 'Excellent Venue!'
    },
    {
      'imageAsset': 'assets/hotel_image5.jpeg',
      'venueName': 'Swagath Grand',
      'userName': 'User name',
      'rating': 4.5,
      'comment': 'Phasellus accumsan imperdiet tempor. Cras tincidunt, arcu nec eleifend porttitor, orci est vehicula.',
      'heading': 'Amazing Service!'
    },
    {
      'imageAsset': 'assets/hotel_image6.jpeg',
      'venueName': 'Swagath Grand',
      'userName': 'User name',
      'rating': 4.5,
      'comment': 'Phasellus accumsan imperdiet tempor. Cras tincidunt, arcu nec eleifend porttitor, orci est vehicula.',
      'heading': 'Memorable Experience'
    },
  ];
class Section extends StatelessWidget {
  final String title;
  final List<Item> items;

  Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) => ItemWidget(item: item)).toList(),
          ),
        ),
      ],
    );
  }
}

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
            Text(item.location, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

               //  const Padding(
//                     padding: EdgeInsets.only(left: 20.0, right: 20, top: 5),
//                     child: Text('Recently viewed',
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                   ),
//                   Container(
//                     width: double.infinity,
//                     padding:
//                         EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
//                     child: propertyState.when(
//                         loading: () =>
//                             Center(child: CircularProgressIndicator()),
//                         error: (error, stack) =>
//                             Center(child: Text('Error: $error')),
//                         data: (properties) {
//                           final property = properties[0];
//                           LatLng latLng =
//                               PropertyLocationConverter.parseLocationString(
//                                   '${property.location}');
//                            String imageurl =
//                               '${Bbapi.baseUrl}' + '${property.propertyPic}';
//                           return Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Image.network(
//                                 imageurl,
//                                 height: 100,
//                                 width: 100,
//                                 fit: BoxFit.fill,
//                               ),
//                               Text(property.pincode!,
//                                   style:
//                                       TextStyle(fontWeight: FontWeight.bold)),
//                             ],
//                           );
//                         }),
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.only(left: 20.0, right: 20, top: 5),
//                     child: Text('Testimonial',
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                   ),
//                   Padding(
//                     padding:
//                         EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
//                     child: Container(
//                       color: Colors.white,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text(
//                               'Banquet Bookz: Event planning made easy! Love the intuitive design.',
//                               textAlign: TextAlign.center),
//                           SizedBox(height: 8),
//                           Text('Kristin Watson',
//                               style: TextStyle(fontWeight: FontWeight.bold)),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: List.generate(
//                                 5,
//                                 (index) => Icon(Icons.star,
//                                     color: Colors.amber, size: 16)),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.only(left: 20.0, right: 20, top: 5),
//                     child: Text('Recent Venue Reviews',
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.all(20),
//                     child: propertyState.when(
//                         loading: () =>
//                             Center(child: CircularProgressIndicator()),
//                         error: (error, stack) =>
//                             Center(child: Text('Error: $error')),
//                         data: (properties) {
//                           return ListView.builder(
//                               physics: NeverScrollableScrollPhysics(),
//                               shrinkWrap: true,
//                               itemCount: properties.length,
//                               itemBuilder: (context, index) {
//                                 // final item = _items[index];
//                                 final property = properties[index];
//                                 LatLng latLng = PropertyLocationConverter
//                                     .parseLocationString(
//                                         '${property.location}');
//                                 String imageurl = '${Bbapi.baseUrl}' +
//                                     '${property.propertyPic}';
//                                 return Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 8.0, vertical: 4.0),
//                                   child: Card(
//                                     elevation: 4.0,
//                                     child: Padding(
//                                       padding: const EdgeInsets.only(
//                                           top: 16.0,
//                                           bottom: 16,
//                                           right: 16,
//                                           left: 25),
//                                       child: Column(
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Container(),
//                                               Image.network(
//                                                 imageurl,
//                                                 width: 50,
//                                                 height: 50,
//                                                 fit: BoxFit.fill,
//                                               ),
//                                               SizedBox(width: 16),
//                                               Expanded(
//                                                 child: Padding(
//                                                   padding:
//                                                       const EdgeInsets.only(
//                                                           left: 7.0),
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       Text(
//                                                         "item.heading",
//                                                         style: const TextStyle(
//                                                             fontSize: 24,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                             color:
//                                                                 Colors.black),
//                                                       ),
//                                                       Row(
//                                                         children: [
//                                                           const Icon(Icons.star,
//                                                               color:
//                                                                   Colors.amber,
//                                                               size: 16),
//                                                           const SizedBox(
//                                                               width: 4),
//                                                           Text(
//                                                               '${property.averageRating} (${property.reviewCount})',
//                                                               style: const TextStyle(
//                                                                   fontStyle:
//                                                                       FontStyle
//                                                                           .italic,
//                                                                   fontSize: 16,
//                                                                   color: Colors
//                                                                       .black)),
//                                                         ],
//                                                       ),
//                                                       Text(
//                                                         '${property.address1} ' +
//                                                             '${property.address2}\n'
//                                                                 '${property.pincode}',
//                                                         style: const TextStyle(
//                                                           fontSize: 16,
//                                                           color: CoustColors
//                                                               .colrSubText,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           SizedBox(
//                                             width: double.infinity,
//                                             child: ElevatedButton(
//                                               onPressed: () async {
//                                                 // Handle button press

//                                                 Navigator.push(
//                                                     context,
//                                                     MaterialPageRoute(
//                                                         builder: (context) =>
//                                                             VenuDetailsScreen(
//                                                                 property:
//                                                                     property)));
//                                               },
//                                               child: const Text('View Details'),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               });
//                         }),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

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

class VenueCard {
  final String name;
  final String location;

  VenueCard({required this.name, required this.location});
}
