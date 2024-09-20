import 'package:flutter/material.dart';

import '../Colors/coustcolors.dart';
import '../Widgets/evaluatedbutton.dart';

class UpcomingbookingsScreen extends StatefulWidget {
  const UpcomingbookingsScreen({super.key});

  @override
  State<UpcomingbookingsScreen> createState() => _UpcomingbookingsScreenState();
}

class _UpcomingbookingsScreenState extends State<UpcomingbookingsScreen> {
  String sName = "Swagath Grand banquet hall";
  String imagePath = "images/flutter.jpg";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
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
                child: Text("Upcoming Bookings",
                    style:
                        TextStyle(color: CoustColors.colrEdtxt4, fontSize: 20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 20, right: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hall Details",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.black),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.asset(
                          imagePath,
                          height: 50,
                          width: 50,
                          fit: BoxFit.fill,
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
                              'Plot No. 2-4, 70/26/1/2, Alkapuri \'X\' Roads, Nagole, Hyderabad, Telangana 500068',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
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
                            '040 2212 3456',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
                              // Handle Get Directions
                            },
                            child: Text(
                              'Get Directions',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                    ],
                  ),
                ),
                SizedBox(height: 8.0),
                ReviewCard(),
                SizedBox(height: 16.0),
                CoustEvalButton(
                  onPressed: () {
                    // Handle book
                  },
                  buttonName: 'Cancle Booking',
                  bgColor: CoustColors.colrButton1,
                  width: double.infinity,
                  radius: 8,
                  FontSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Colors.white,
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_today, size: 16.0),
            SizedBox(width: 8.0),
            Expanded(
                child: Text('Reserved on Saturday,30 Feb 2024 @ 19:33',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible)),
          ],
        ),
      ),
    );
  }
}
