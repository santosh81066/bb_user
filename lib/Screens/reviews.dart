import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Colors/coustcolors.dart';
import '../Providers/rating.dart';
import '../models/propertystate.dart';

class ReviewScreen extends StatefulWidget {
  final Propertystate property;
  const ReviewScreen({super.key, required this.property});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 3;
  //TextEditingController _titleController = TextEditingController();
  TextEditingController _reviewController = TextEditingController();
  @override
  Widget build(BuildContext context) {
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
                child: Text("Add a Review ",
                    style:
                        TextStyle(color: CoustColors.colrEdtxt4, fontSize: 20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 150.0, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How would you like to rate?',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
                SizedBox(height: 20.0),
                const Text(
                  'Write your review',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Type here',
                  ),
                ),
                const SizedBox(height: 20.0),
                SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder:
                        (BuildContext context, WidgetRef ref, Widget? child) {
                      return ElevatedButton(
                        onPressed: () {
                          ref.read(ratingprovider.notifier).postreviews(
                              context,
                              widget.property,
                              _rating,
                              _reviewController.text.trim(),
                              ref);
                        },
                        child: Text('Submit'),
                        style: ElevatedButton.styleFrom(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
