import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/propertystate.dart';
import '../models/ratingmodel.dart';
import '../utils/bbapi.dart';

class RatingNotifier extends StateNotifier<AsyncValue<List<RatingState>>> {
  RatingNotifier() : super((AsyncValue.loading()));

  Future<void> postreviews(BuildContext context, Propertystate property,
      double? rating, String? review, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final extractData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    String token = extractData['token'];
    print("getProperties: ${token}");
    const url = Bbapi.post_review;
    try {
      var response = await http.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token $token',
          },
          body: json.encode({
            "property": property.id!,
            "rating": rating!,
            "review": review!,
          }));
      print("username: ${property.id!}  \n $rating \n $review");
      var userDetails = json.decode(response.body);
      print('booking response:$userDetails');
      print('booking response Status Code:${response.statusCode}');
      switch (response.statusCode) {
        case 201:
          print('success');
          showDialog(
            context: context!,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Success'),
                content: const Text('Review successful'),
                actions: [
                  ElevatedButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          //  Navigator.push(context, MaterialPageRoute(builder: (context) => VenuDetailsScreen(property: property),
          //                           ),
          //                         );
          // Navigator.of(context).pushNamed('/');  //Goto Login page if Registered succesfully
          break;
        case 400:
          showDialog(
              context: context!,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Failed'),
                  content: Text("$userDetails"),
                  actions: [
                    ElevatedButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
          break;
      }
    } catch (e) {
      print(e.toString());
    }
  }
  // Handle other status codes as needed

  Future<List<RatingState>> getreviews(
      BuildContext context, Propertystate property, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final extractData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    String token = extractData['token'];
    var url = '${Bbapi.get_review}' + '${property.id!}/';
    print("getProperties: ${url}");
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );
      print("HTTP Response: ${response.statusCode} - ${response.body}");
      var ratingDetails = json.decode(response.body);
      print("Response: ${ratingDetails}");
      if (response.statusCode == 200) {
        print("Response 200");
        List<dynamic> userDetails = json.decode(response.body);
        if (userDetails.isNotEmpty) {
          //final property = userDetails.first;
          final reviews =
              userDetails.map((json) => RatingState.fromJson(json)).toList();
          state = AsyncValue.data(reviews);

          return userDetails.map((json) => RatingState.fromJson(json)).toList();
        } else {
          print("Response 200 but empty body");
          throw Exception('No properties found');
        }
      } else {
        print("Failed response: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      print("Exception caught: $e");
      throw Exception('Failed to load properties');
    }
  }
}

final ratingprovider =
    StateNotifierProvider<RatingNotifier, AsyncValue<List<RatingState>>>((ref) {
  return RatingNotifier();
});
