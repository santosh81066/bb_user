import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Rating state provider
final ratingProvider =
    StateProvider<int>((ref) => 1); // Default: 1 star selected

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReviewPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<ReviewPage> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRating = ref.watch(ratingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'M.N conventional hall',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // // User profile section
                  // Row(
                  //   children: [
                  //     const CircleAvatar(
                  //       radius: 30,
                  //       backgroundImage: AssetImage('assets/profile_image.jpg'),
                  //       // Replace with NetworkImage for remote images
                  //       // backgroundImage: NetworkImage('https://example.com/image.jpg'),
                  //     ),
                  //     const SizedBox(width: 16),
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Row(
                  //           children: [
                  //             const Text(
                  //               'Sandeep sharma',
                  //               style: TextStyle(
                  //                 fontSize: 22,
                  //                 fontWeight: FontWeight.bold,
                  //               ),
                  //             ),
                  //             const SizedBox(width: 5),
                  //             Container(
                  //               padding: const EdgeInsets.all(1),
                  //               decoration: BoxDecoration(
                  //                 color: Colors.green,
                  //                 borderRadius: BorderRadius.circular(10),
                  //               ),
                  //               child: const Icon(
                  //                 Icons.check,
                  //                 color: Colors.white,
                  //                 size: 14,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //         const Text(
                  //           'User',
                  //           style: TextStyle(
                  //             fontSize: 16,
                  //             color: Colors.grey,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ],
                  // ),

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
                        onTap: () =>
                            ref.read(ratingProvider.notifier).state = index + 1,
                        child: Icon(
                          index < currentRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Color(0xFF6418C3),
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
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF6418C3), width: 1),
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
                      border: Border.all(color: Color(0xFF6418C3), width: 1),
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
                      onPressed: () {
                        // TODO: Handle submission
                        final rating = ref.read(ratingProvider);
                        final comment = _commentController.text;
                        print('Rating: $rating, Comment: $comment');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6418C3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
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
        ],
      ),
    );
  }
}
