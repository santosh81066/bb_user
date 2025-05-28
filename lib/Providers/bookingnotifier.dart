/*
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
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );
      var booked_dates = json.decode(response.body);
      if (response.statusCode == 200) {
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
          throw Exception('No properties found');
        }
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
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
      var booked_dates = json.decode(response.body);
      if (response.statusCode == 201) {
        showDialog(
          context: context,
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
        throw Exception('Failed to load properties');
      }
    } catch (e) {
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
*/
