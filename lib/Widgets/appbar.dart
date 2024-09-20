import 'package:flutter/material.dart';

import '../Colors/coustcolors.dart';

class CoustAppbar extends StatelessWidget {
  const CoustAppbar({super.key, required this.title, this.username});
  final String title;
  final String? username;
  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  Text(title,
                      style: TextStyle(
                          color: CoustColors.colrEdtxt4, fontSize: 20)),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(username!,
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
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    child: IconButton(
                      icon: const Icon(Icons.notifications),
                      color: CoustColors.colrHighlightedText,
                      onPressed: () {
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
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                    child: IconButton(
                      icon: const Icon(Icons.person),
                      color: CoustColors.colrHighlightedText,
                      onPressed: () {
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
    );
  }
}
