
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

class _ReviewPageState extends ConsumerState<ReviewPage>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _ratingController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _ratingAnimation;

  // User ID would normally come from auth state, for this example we'll hardcode it
  final int userId = 29; // This should be dynamically fetched in a real app

  String? reviewType;
  int? itemId;
  String? itemName;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _ratingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _ratingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _ratingController,
      curve: Curves.bounceOut,
    ));

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

      // Start animations
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _slideController.forward();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        _scaleController.forward();
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ref.read(selectedImagesProvider.notifier).addImage(image.path);
        // Animate the new image
        _scaleController.reset();
        _scaleController.forward();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a comment'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final rating = ref.read(ratingProvider);
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (itemId == null || reviewType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Missing review information'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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

  void _onRatingTap(int rating) {
    ref.read(ratingProvider.notifier).state = rating;
    _ratingController.reset();
    _ratingController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final isLargeScreen = screenWidth >= 600;

    // Responsive padding and sizing
    final horizontalPadding = isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0;
    final headerPadding = screenHeight * 0.025;
    final sectionSpacing = screenHeight * 0.035;
    final imageSize = isSmallScreen ? 90.0 : isMediumScreen ? 110.0 : 130.0;
    final starSize = isSmallScreen ? 35.0 : isMediumScreen ? 40.0 : 45.0;
    final fontSize = isSmallScreen ? 20.0 : 22.0;
    final buttonHeight = isSmallScreen ? 50.0 : 55.0;

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
              SnackBar(
                content: Text(current.value!.messages.first),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
              SnackBar(
                content: Text('Error: ${current.error}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Animated blue header with back button and title
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: headerPadding,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6418C3),
                        Color(0xFF8A2BE2),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6418C3).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            itemName ?? 'Add Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: sectionSpacing),

                      // Animated Rating section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rate,
                                    color: const Color(0xFF6418C3),
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Give me rating',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              AnimatedBuilder(
                                animation: _ratingAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (0.2 * _ratingAnimation.value),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: List.generate(5, (index) {
                                        return GestureDetector(
                                          onTap: () => _onRatingTap(index + 1),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: index < currentRating
                                                  ? const Color(0xFF6418C3).withOpacity(0.1)
                                                  : Colors.transparent,
                                            ),
                                            child: Icon(
                                              index < currentRating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: index < currentRating
                                                  ? const Color(0xFFF6B230)
                                                  : Colors.grey[400],
                                              size: starSize,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      // Animated Add media section
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    color: const Color(0xFF6418C3),
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add media',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  // Add image button with animation
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: imageSize,
                                      height: imageSize,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF6418C3),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white,
                                            const Color(0xFF6418C3).withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: isSmallScreen ? 35 : 40,
                                            color: const Color(0xFF6418C3),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Add Photo',
                                            style: TextStyle(
                                              color: const Color(0xFF6418C3),
                                              fontSize: isSmallScreen ? 12 : 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Selected images with enhanced animations
                                  ...selectedImages.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final imagePath = entry.value;
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 300 + (index * 100)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: imageSize,
                                                height: imageSize,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                  image: DecorationImage(
                                                    image: FileImage(File(imagePath)),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -8,
                                                right: -8,
                                                child: GestureDetector(
                                                  onTap: () => ref
                                                      .read(selectedImagesProvider.notifier)
                                                      .removeImage(imagePath),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
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
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      // Animated Comment section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.rate_review,
                                    color: const Color(0xFF6418C3),
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Comment',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF6418C3).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6418C3).withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _commentController,
                                  maxLines: isSmallScreen ? 4 : 5,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Your review will help us grow and make the experience more user-friendly for everyone",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    contentPadding: const EdgeInsets.all(20),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      // Animated Submit button
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6418C3),
                                foregroundColor: Colors.white,
                                elevation: _isSubmitting ? 0 : 8,
                                shadowColor: const Color(0xFF6418C3).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                disabledBackgroundColor: Colors.grey[400],
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Submit Review',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom spacing for better scrolling experience
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}