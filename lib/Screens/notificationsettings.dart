import 'package:flutter/material.dart';

import '../Colors/coustcolors.dart';
import '../Widgets/togglebutton.dart';

class NotificationSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
                child: Text("Notification Settings",
                    style:
                        TextStyle(color: CoustColors.colrEdtxt4, fontSize: 20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    "Mobile Notification",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  CoustTogglebutton(lable: 'Promotions'),
                  CoustTogglebutton(lable: 'Reviews'),
                  CoustTogglebutton(lable: 'System Updates'),
                  const Text(
                    "Event Notification",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  CoustTogglebutton(lable: 'Booking'),
                  CoustTogglebutton(lable: 'Cancellations '),
                  CoustTogglebutton(lable: 'Upcoming'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
