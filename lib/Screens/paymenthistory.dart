import 'package:flutter/material.dart';

import '../Colors/coustcolors.dart';

class PaymenthistoryScreen extends StatefulWidget {
  const PaymenthistoryScreen({super.key});

  @override
  State<PaymenthistoryScreen> createState() => _PaymenthistoryScreenState();
}

class _PaymenthistoryScreenState extends State<PaymenthistoryScreen> {
  final List _items = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 5; i++) {
      _items.add("");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
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
                    child: Text("Payment History",
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
            child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      elevation: 4.0,
                      child: Padding(
                          padding: const EdgeInsets.only(
                              top: 16.0, bottom: 16, right: 16, left: 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Event name",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    "Venue name",
                                  ),
                                  Text("Details"),
                                  Text("Date:"),
                                ],
                              ),
                              Text(
                                "6,055 Dr",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
