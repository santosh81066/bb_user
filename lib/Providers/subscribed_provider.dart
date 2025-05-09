import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscribed_model.dart';
import '../utils/bbapi.dart';

class SubscriptionNotifier extends StateNotifier<List<Subscription>> {
  SubscriptionNotifier() : super([]);

  Future<void> fetchSubscriptions() async {
    try {
      final response = await http.get(
        Uri.parse(Bbapi.addpropertyplan),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> subscriptionsData = responseData['data'];

        // Parse subscriptions
        final subscriptions = subscriptionsData
            .map((json) => Subscription.fromJson(json))
            .toList();

        // Sort by start_time (newest first)
        subscriptions.sort((a, b) => b.startTime.compareTo(a.startTime));

        state = subscriptions;
      } else {
        print('Failed to load subscriptions: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception when fetching subscriptions: $e');
    }
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, List<Subscription>>((ref) {
  return SubscriptionNotifier();
});
