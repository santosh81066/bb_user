import 'package:flutter/material.dart';
import '../Colors/coustcolors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Notification toggle states
  Map<String, bool> notificationStates = {
    'Promotions': false,
    'Reviews': true,
    'System Updates': true,
    'Booking': true,
    'Cancellations': true,
    'Upcoming': true,
    'Payment Confirmations': true,
    'New Features': false,
  };

  // Category data for better organization
  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Mobile Notifications',
      'icon': Icons.notifications_active,
      'items': ['Promotions', 'Reviews', 'System Updates', 'New Features'],
      'description': 'Manage notifications sent directly to your device'
    },
    {
      'title': 'Event Notifications',
      'icon': Icons.event_available,
      'items': ['Booking', 'Cancellations', 'Upcoming', 'Payment Confirmations'],
      'description': 'Control notifications related to your scheduled events'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      appBar: AppBar(
        backgroundColor: Color(0xFF6418C3),
        elevation: 0,
        title: Text(
          "Notification Settings",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done, color: Colors.white),
            onPressed: () {
              // Save settings and show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Settings saved successfully!'),
                  backgroundColor: Color(0xFF6418C3),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Master toggle for all notifications
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications, color: Color(0xFF6418C3), size: 24),
                        SizedBox(width: 12),
                        Text(
                          "All Notifications",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Switch(
                          value: !notificationStates.values.contains(false),
                          onChanged: (value) {
                            setState(() {
                              notificationStates.forEach((key, _) {
                                notificationStates[key] = value;
                              });
                            });
                          },
                          activeColor: Color(0xFF6418C3),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Toggle to enable or disable all notifications at once",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Build each category
            ...categories.map((category) => _buildNotificationCategory(category)).toList(),

            SizedBox(height: 16),

            // Additional instructions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Note:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You can customize your notification preferences anytime. These settings apply to both the app and email notifications.",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Reset to default settings
                      setState(() {
                        notificationStates = {
                          'Promotions': false,
                          'Reviews': true,
                          'System Updates': true,
                          'Booking': true,
                          'Cancellations': true,
                          'Upcoming': true,
                          'Payment Confirmations': true,
                          'New Features': false,
                        };
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reset to default settings'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Reset to Default Settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCategory(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title with icon
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(category['icon'], color: Color(0xFF6418C3), size: 22),
              SizedBox(width: 10),
              Text(
                category['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Category description
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            category['description'],
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),

        // Category items
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: category['items'].map<Widget>((item) {
                return _buildNotificationToggle(item);
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNotificationToggle(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getDescriptionForLabel(label),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: notificationStates[label] ?? false,
            onChanged: (value) {
              setState(() {
                notificationStates[label] = value;
              });
            },
            activeColor: Color(0xFF6418C3),
          ),
        ],
      ),
    );
  }

  // Helper method to get descriptions for each notification type
  String _getDescriptionForLabel(String label) {
    switch (label) {
      case 'Promotions':
        return 'Stay updated with special offers and discounts';
      case 'Reviews':
        return 'Get notified when someone leaves a review';
      case 'System Updates':
        return 'Important updates about system changes';
      case 'Booking':
        return 'Notifications when a booking is confirmed';
      case 'Cancellations':
        return 'Alerts about cancelled bookings or events';
      case 'Upcoming':
        return 'Reminders about your upcoming events';
      case 'Payment Confirmations':
        return 'Receive receipts and payment confirmations';
      case 'New Features':
        return 'Be the first to know about new app features';
      default:
        return 'Manage notification preferences';
    }
  }
}