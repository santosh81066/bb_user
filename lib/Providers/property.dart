import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/propertystate.dart';
import '../utils/bbapi.dart';

class PropertyNotifier extends StateNotifier<AsyncValue<List<Propertystate>>> {
  PropertyNotifier() : super(AsyncValue.loading());

  Future<List<Propertystate>> getProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final extractData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    String token = extractData['token'];
    print("getProperties: ${token}");

    const url = Bbapi.properties;
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );
      print("HTTP Response: ${response.statusCode} - ${response.body}");
      var userDetails = json.decode(response.body);
      print("Response: ${userDetails}");
      if (response.statusCode == 200) {
        print("Response 200");
        List<dynamic> userDetails = json.decode(response.body);
        if (userDetails.isNotEmpty) {
          //final property = userDetails.first;
          final properties =
              userDetails.map((json) => Propertystate.fromJson(json)).toList();
          state = AsyncValue.data(properties);

          return userDetails
              .map((json) => Propertystate.fromJson(json))
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
}

final propertyprovider =
    StateNotifierProvider<PropertyNotifier, AsyncValue<List<Propertystate>>>(
        (ref) {
  return PropertyNotifier();
});
