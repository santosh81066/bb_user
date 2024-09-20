import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookingstate.dart';
import '../models/propertystate.dart';
import '../utils/bbapi.dart';

// Define the StateNotifier
class bookingNotifier extends StateNotifier<AsyncValue<List<BookingState>>> {
  bookingNotifier() : super((AsyncValue.loading()));

  Future<List<BookingState>> fetchBookedDates(
      BuildContext context, Propertystate property, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final extractData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    String token = extractData['token'];
    var url = '${Bbapi.booked_dates}' + '${property.id!}/';
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
      var booked_dates = json.decode(response.body);
      print("Response: ${booked_dates}");
      if (response.statusCode == 200) {
        print("Response 200");
        List<dynamic> booked_dates = json.decode(response.body);
        if (booked_dates.isNotEmpty) {
          //final property = userDetails.first;
          final reviews =
              booked_dates.map((json) => BookingState.fromJson(json)).toList();
          state = AsyncValue.data(reviews);

          return booked_dates
              .map((json) => BookingState.fromJson(json))
              .toList();
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

  Future<void> Bookproperties(BuildContext context, Propertystate property,
      String? date, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final extractData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    String token = extractData['token'];
    var url = Bbapi.book_property;
    print("Bookproperties: ${url}");
    try {
      var response = await http.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token $token',
          },
          body: json.encode({
            "property": property.id!,
            "date": date!,
          }));
      print(
          "Bookproperties HTTP Response: ${response.statusCode} - ${response.body}");
      var booked_dates = json.decode(response.body);
      print("Bookproperties Response: ${booked_dates}");
      if (response.statusCode == 201) {
        print("Response 200");
        showDialog(
          context: context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Updated successful'),
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
      } else {
        print(
            "Bookproperties Failed response: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      print("Bookproperties Exception caught: $e");
      throw Exception('Failed to load properties');
    }
  }
}

// Define the StateProvider
final bookingProvider =
    StateNotifierProvider<bookingNotifier, AsyncValue<List<BookingState>>>(
        (ref) {
  return bookingNotifier();
});
