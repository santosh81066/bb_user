import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/get_review_model.dart';
import '../models/review_model.dart';
import '../providers/auth.dart';
import '../Providers/venues_provider.dart';

class ReviewsNotifier extends StateNotifier<AsyncValue<List<Review>>> {
  final Ref ref;

  ReviewsNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> fetchReviews() async {
    state = const AsyncValue.loading();

    try {
      // Get auth state
      final authState = ref.read(authprovider);

      // Debug info
      print("Fetching reviews with token: ${authState.token}");

      // Make API request - fixing the endpoint URL
      // Note: The endpoint might be '/getreview' instead of '/bbaddreview'
      final response = await http.get(
        Uri.parse('https://www.gocodedesigners.com/bbaddreview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authState.token}',
        },
      );

      // Debug info
      print("Review response status: ${response.statusCode}");
      print("Review response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final reviewsData = responseData['data'] as List<dynamic>;
          final reviews =
              reviewsData.map((review) => Review.fromJson(review)).toList();

          // Get properties data to populate names
          final propertyState = ref.read(propertyNotifierProvider);
          final propertiesData = propertyState.data;

          if (propertiesData != null) {
            for (var review in reviews) {
              // Handle property reviews
              if (review.propertyId != null) {
                for (var property in propertiesData) {
                  if (property.propertyId == review.propertyId) {
                    review.propertyName = property.propertyName;
                    break;
                  }
                }
              }

              // Handle hall reviews
              if (review.hallId != null) {
                for (var property in propertiesData) {
                  if (property.halls != null) {
                    for (var hall in property.halls!) {
                      if (hall.hallId == review.hallId) {
                        //review.hallName = hall.hallName;
                        review.propertyName = property.propertyName;
                        break;
                      }
                    }
                  }
                  if (review.hallName != null) break; // Stop if found
                }
              }
            }
          }

          state = AsyncValue.data(reviews);
        } else {
          state =
              AsyncValue.error('Invalid response format', StackTrace.current);
        }
      } else {
        state = AsyncValue.error(
            'Failed to load reviews: ${response.statusCode}',
            StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error('Error: $error', stackTrace);
    }
  }
}

final reviewsProvider =
    StateNotifierProvider<ReviewsNotifier, AsyncValue<List<Review>>>(
  (ref) => ReviewsNotifier(ref),
);
