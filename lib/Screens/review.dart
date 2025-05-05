import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Providers/review_provider.dart';
import '../models/review_model.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // User ID would normally come from auth state, for this example we'll hardcode it
  final int userId = 29; // This should be dynamically fetched in a real app

  String? reviewType;
  int? itemId;
  String? itemName;

  @override
  void initState() {
    super.initState();

    // Reset the rating when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset rating and images when page initializes
      ref.read(ratingProvider.notifier).state = 0;
      ref.read(selectedImagesProvider.notifier).clearImages();

      // Get arguments from navigation
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          reviewType = args['type'] as String?;
          itemId = args['id'] as int?;
          itemName = args['name'] as String?;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ref.read(selectedImagesProvider.notifier).addImage(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a comment')),
      );
      return;
    }

    final rating = ref.read(ratingProvider);
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (itemId == null || reviewType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing review information')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final comment = _commentController.text;
    final images = ref.read(selectedImagesProvider);

    final reviewRequest = ReviewRequest(
      review: comment,
      rating: rating,
      userId: userId,
      propertyId: reviewType == 'property' ? itemId : null,
      hallId: reviewType == 'hall' ? itemId : null,
      imagePaths: images,
    );

    await ref.read(reviewStateProvider.notifier).submitReview(reviewRequest);

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRating = ref.watch(ratingProvider);
    final selectedImages = ref.watch(selectedImagesProvider);
    final reviewState = ref.watch(reviewStateProvider);

    // Handle review submission state
    ref.listen<AsyncValue<ReviewResponse?>>(reviewStateProvider,
        (previous, current) {
      if (previous?.isLoading == true &&
          current.hasValue &&
          current.value != null) {
        // Success case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(current.value!.messages.first)),
        );

        // Reset form and navigate back after successful submission
        if (current.value!.success) {
          ref.read(selectedImagesProvider.notifier).clearImages();
          ref.read(ratingProvider.notifier).state = 0;
          _commentController.clear();

          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
          });
        }
      } else if (current.hasError) {
        // Error case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${current.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Blue header with back button and title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF6418C3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      itemName ?? 'Add Review',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),

                    // Rating section
                    const Text(
                      'Give me rating',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => ref.read(ratingProvider.notifier).state =
                              index + 1,
                          child: Icon(
                            index < currentRating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFF6418C3),
                            size: 40,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 30),

                    // Add media section
                    const Text(
                      'Add media',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Add image button
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF6418C3), width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_circle_outline,
                                size: 50,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        // Selected images
                        ...selectedImages
                            .map((imagePath) => Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: FileImage(File(imagePath)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -10,
                                      right: -10,
                                      child: GestureDetector(
                                        onTap: () => ref
                                            .read(
                                                selectedImagesProvider.notifier)
                                            .removeImage(imagePath),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Comment section
                    const Text(
                      'Comment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF6418C3), width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              "Your review's will help us grow and make the experience more user-friendly for everyone",
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6418C3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
