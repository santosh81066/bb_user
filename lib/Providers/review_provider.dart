import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';

// Provider for the review service
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

// Provider for the rating selection (0-5 stars, 0 means unselected)
// Using StateProvider for simple state management
final ratingProvider = StateProvider<int>((ref) => 0);

// Provider for managing the review state
final reviewStateProvider =
    StateNotifierProvider<ReviewStateNotifier, AsyncValue<ReviewResponse?>>(
        (ref) {
  final reviewService = ref.read(reviewServiceProvider);
  return ReviewStateNotifier(reviewService);
});

// State notifier for review operations
class ReviewStateNotifier extends StateNotifier<AsyncValue<ReviewResponse?>> {
  final ReviewService _reviewService;

  ReviewStateNotifier(this._reviewService) : super(const AsyncValue.data(null));

  Future<void> submitReview(ReviewRequest reviewRequest) async {
    state = const AsyncValue.loading();

    try {
      final response = await _reviewService.submitReview(reviewRequest);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }
}

// Provider for selected images
final selectedImagesProvider =
    StateNotifierProvider<SelectedImagesNotifier, List<String>>((ref) {
  return SelectedImagesNotifier();
});

class SelectedImagesNotifier extends StateNotifier<List<String>> {
  SelectedImagesNotifier() : super([]);

  void addImage(String imagePath) {
    state = [...state, imagePath];
  }

  void removeImage(String imagePath) {
    state = state.where((path) => path != imagePath).toList();
  }

  void clearImages() {
    state = [];
  }
}
