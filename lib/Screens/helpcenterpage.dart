import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6418C3),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality would go here
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EAFA), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for help topics...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF6418C3)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Common questions section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6418C3),
              ),
            ),
            const SizedBox(height: 16),

            // FAQ Items
            _buildHelpCard(
              context,
              'How to use the app?',
              'We\'ve designed our app to be intuitive and user-friendly. You can navigate through different sections using the bottom navigation bar. Swipe right to go back to the previous screen. Tap on items to view more details or perform actions.\n\nTo customize your experience, visit the Settings page accessible from your profile.',
              Icons.phone_android,
            ),

            _buildHelpCard(
              context,
              'Account Management',
              'To update your profile information, go to the Profile tab and tap on "Edit Profile". You can change your display name, profile picture, and other personal details.\n\nTo change your password, go to Settings > Security > Change Password. For security reasons, you\'ll need to enter your current password first.\n\nIf you want to delete your account, please contact our support team through the "Contact Us" section.',
              Icons.person,
            ),

            _buildHelpCard(
              context,
              'Payment & Refunds',
              'We accept various payment methods including credit/debit cards, PayPal, and Apple Pay. All transactions are secure and encrypted.\n\nOur refund policy allows for refunds within 14 days of purchase if you\'re not satisfied with our service. To request a refund, go to Settings > Billing > Request Refund or contact our support team.',
              Icons.payment,
            ),

            _buildHelpCard(
              context,
              'Troubleshooting',
              'If you\'re experiencing issues with the app, try these steps:\n\n1. Ensure your app is updated to the latest version\n2. Restart the app\n3. Check your internet connection\n4. Restart your device\n\nIf problems persist, please contact our support team with details about the issue.',
              Icons.build,
            ),

            const SizedBox(height: 24),

            // Contact support section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6418C3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Our support team is ready to assist you with any questions or concerns',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Contact support action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6418C3),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Contact Support'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context, String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(
            icon,
            color: const Color(0xFF6418C3),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // "Read more" action
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF6418C3),
              ),
              child: const Text('Read more'),
            ),
          ],
        ),
      ),
    );
  }
}