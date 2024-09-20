import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../Colors/coustcolors.dart';
import '../Providers/loaded.dart';
import '../Providers/rating.dart';
import '../Widgets/evaluatedbutton.dart';
import '../models/propertystate.dart';
import '../models/ratingmodel.dart';
import '../utils/bbapi.dart';
import 'bookvenue.dart';
import 'reviews.dart';

class VenuDetailsScreen extends ConsumerStatefulWidget {
  final Propertystate property;
  const VenuDetailsScreen({super.key, required this.property});

  @override
  ConsumerState<VenuDetailsScreen> createState() => _VenuDetailsScreenState();
}

class _VenuDetailsScreenState extends ConsumerState<VenuDetailsScreen> {
  String sName = "Swagath Grand banquet hall";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //ref.watch(authprovider.notifier).tryAutoLogin(),
    //ref.read(propertyprovider.notifier).getProperties();
    //PropertyNotifier().getProperties();
    ref.read(ratingprovider.notifier).getreviews(context, widget.property, ref);
  }

  @override
  Widget build(BuildContext context) {
    final ratingstate = ref.watch(ratingprovider);
    Propertystate property = widget.property;

    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Container(
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
                padding: EdgeInsets.only(top: 25.0, left: 15),
                child: Text("Venue Details",
                    style:
                        TextStyle(color: CoustColors.colrEdtxt4, fontSize: 20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 150.0, left: 20, right: 20),
            child: SingleChildScrollView(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  print("build vendorDetails");

                  print("Details ${property}");
                  // final property = ref.watch(propertyprovider);
                  // print("property state : ${property.state}");
                  // final propertyNotifier = ref.watch(propertyprovider.notifier);
                  var ismapsenable = ref.watch(enableMaps); // Get provider
                  LatLng latLng = PropertyLocationConverter.parseLocationString(
                      '${property.location!}');
                  String imageurl =
                      '${Bbapi.baseUrl2}' + '${property.propertyPic!}';
                  print("Url: $imageurl");
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Hall Details",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.black),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                imageurl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              sName,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            const Text(
                              'Price',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    '${property.address1!}\n' +
                                        '${property.address2!}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Icon(Icons.phone, color: Colors.grey),
                                SizedBox(width: 8.0),
                                Text(
                                  '${property.state!}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Icon(Icons.email, color: Colors.grey),
                                SizedBox(width: 8.0),
                                Text(
                                  'swagathgrand@gmail.com',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Icon(Icons.directions, color: Colors.teal),
                                SizedBox(width: 8.0),
                                TextButton(
                                  onPressed: () {
                                    ref.read(enableMaps.notifier).state = true;
                                    // Handle Get Directions
                                  },
                                  child: Text(
                                    'Get Directions',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.teal),
                                  ),
                                ),
                              ],
                            ),
                            ismapsenable == true
                                ? SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: latLng,
                                        initialZoom: 15,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          subdomains: ['a', 'b', 'c'],
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              width: 80.0,
                                              height: 80.0,
                                              point: latLng,
                                              child: Container(
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                            SizedBox(height: 16.0),
                            Text(
                              'Categories',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            Wrap(
                              spacing: 8.0,
                              children: [
                                Chip(
                                  label: Text('Banquet Hall'),
                                  backgroundColor: Colors.purple[100],
                                ),
                                Chip(
                                  label: Text('Hotel'),
                                  backgroundColor: Colors.purple[100],
                                ),
                                Chip(
                                  label: Text('Function Hall'),
                                  backgroundColor: Colors.purple[100],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Customer reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Container(
                        color: Colors.white,
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StarRating(
                              rating: property.averageRating!,
                              starCount: 5,
                              color: Colors.amber,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                ),
                                Text('${property.averageRating!} out of 5'),
                                SizedBox(width: 8.0),
                                Text('${property.reviewCount} total ratings'),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    // Handle view more reviews
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: true,
                        child: Column(
                          children: [
                            Text(
                              'Recent reviews',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.0),
                            ratingstate.when(
                                loading: () {
                                  return Container();
                                },
                                // loading: () =>
                                //     Center(child: CircularProgressIndicator()),
                                error: (error, stack) =>
                                    Center(child: Text('Error: $error')),
                                data: (reviews) {
                                  print("length: ${reviews.length}");
                                  return ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: reviews.length,
                                      itemBuilder: (context, index) {
                                        // final item = _items[index];
                                        final review = reviews[index];
                                        return reviewcard(review);
                                      });
                                }),
                            SizedBox(height: 16.0),
                          ],
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        width: MediaQuery.of(context).size.width,
                        child: TextButton(
                          onPressed: () {
                            // Navigator.of(context).pushNamed('/review');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReviewScreen(property: property),
                              ),
                            );
                            //Go to next page
                          },
                          child: Text('Leave a review',
                              style: const TextStyle(
                                  color: CoustColors.colrHighlightedText)),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      SizedBox(
                        width: double.infinity,
                        child: CoustEvalButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookVenueScreen(property: property),
                                ));
                          },
                          buttonName: 'Book',
                          bgColor: CoustColors.colrButton1,
                          width: double.infinity,
                          radius: 8,
                          FontSize: 20,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget reviewcard(RatingState rateing) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://via.placeholder.com/50'), // Placeholder image URL
                ),
                SizedBox(width: 8.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top reviews',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    StarRating(
                      rating: rateing.rating!,
                      starCount: 5,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(rateing.review!,
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4.0),
            // Text(
            //   'In a laoreet purus. Integer turpis quam, laoreet id orci nec, ultrices lacinia nunc. Aliquam erat vo',
            //   style: TextStyle(color: Colors.grey),
            // ),
          ],
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final int rating;
  final int starCount;
  final Color color;

  StarRating({this.rating = 0, this.starCount = 5, this.color = Colors.yellow});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          color: color,
        );
      }),
    );
  }
}

class PropertyLocationConverter {
  // Function to convert a location string to LatLng
  static LatLng parseLocationString(String location) {
    final parts = location.split(',');
    final latitude = double.parse(parts[0]);
    final longitude = double.parse(parts[1]);
    return LatLng(latitude, longitude);
  }
}
