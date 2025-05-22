import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/get_properties_model.dart';
import '../models/get_review_model.dart';
import '../providers/auth.dart';
import '../Providers/venues_provider.dart';

class ReviewsNotifier extends StateNotifier<AsyncValue<List<Review>>> {
  final Ref ref;

  ReviewsNotifier(this.ref) : super(const AsyncValue.loading()) {
    print("ReviewsNotifier created");
    fetchReviews(null);
  }

  @override
  void dispose() {
    print("ReviewsNotifier disposed");
    super.dispose();
  }

  Future<void> fetchReviews(dynamic venueType) async {
    state = const AsyncValue.loading();

    try {
      // Get auth state
      final authState = ref.read(authprovider);

      // Debug info
      print("Fetching reviews with token: ${authState.token}");

      // Make API request
      final response = await http.get(
        Uri.parse('http://www.gocodedesigners.com/bbaddreview'),
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
                        review.hallName = hall.name;
                        review.propertyName = property.propertyName;
                        break;
                      }
                    }
                  }
                  if (review.hallName != null) break;
                }
              }
            }
          }

          state = AsyncValue.data(reviews);
        } else {
          state = AsyncValue.error('Invalid response format', StackTrace.current);
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

  // Method to refresh reviews
  Future<void> refreshReviews() async {
    await fetchReviews(null);
  }
}

// Updated provider with autoDispose and keepAlive
final reviewsProvider = StateNotifierProvider.autoDispose<ReviewsNotifier, AsyncValue<List<Review>>>((ref) {
  final notifier = ReviewsNotifier(ref);

  // Keep the provider alive to prevent recreation
  ref.keepAlive();

  return notifier;
});