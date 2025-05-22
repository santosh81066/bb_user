import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Add navigation callback
  static Function(Map<String, dynamic>)? onNotificationTapped;

  // Notification types that match your UI
  static const Map<String, String> notificationTypes = {
    'promotions': 'Promotions',
    'reviews': 'Reviews',
    'system_updates': 'System Updates',
    'booking': 'Booking',
    'cancellations': 'Cancellations',
    'upcoming': 'Upcoming',
    'payment_confirmations': 'Payment Confirmations',
    'new_features': 'New Features',
  };

  static Future<void> initialize() async {
    try {
      // Request permission for iOS with more comprehensive options
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications with proper Android channel
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android (IMPORTANT!)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Get initial message if app was opened from notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Subscribe to topics based on user preferences
      await _subscribeToTopics();

      print('Firebase Notification Service initialized successfully');
    } catch (e) {
      print('Error initializing Firebase Notification Service: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      print('Copy this token for testing: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Method to print token to console for easy copying
  static Future<void> printTokenToConsole() async {
    String? token = await getToken();
    if (token != null) {
      print('=================================');
      print('FCM TOKEN FOR TESTING:');
      print(token);
      print('=================================');
    }
  }

  // Enhanced foreground message handler
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.toMap()}');

    // Check if this notification type is enabled
    String? notificationType = message.data['type'];
    if (notificationType != null && !await _isNotificationEnabled(notificationType)) {
      print('Notification type $notificationType is disabled, skipping');
      return; // Don't show if disabled
    }

    // Show local notification
    await _showLocalNotification(message);
  }

  // Enhanced local notification display
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      // Add custom sound if needed
      // sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped with payload: ${response.payload}');
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('Firebase notification tapped: ${message.data}');
    _handleNotificationData(message.data);
  }

  // Enhanced navigation handler
  static void _handleNotificationData(Map<String, dynamic> data) {
    print('Handling notification data: $data');

    // Call the navigation callback if set
    if (onNotificationTapped != null) {
      onNotificationTapped!(data);
    } else {
      // Fallback navigation logic
      String? type = data['type'];
      String? screen = data['screen'];
      String? bookingId = data['booking_id'];

      print('Notification tapped: Type: $type, Screen: $screen, BookingId: $bookingId');

      // You can add default navigation logic here
      // For example, navigate to specific screens based on type
    }
  }

  static Future<void> _subscribeToTopics() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      for (String key in notificationTypes.keys) {
        bool isEnabled = prefs.getBool('notification_$key') ?? _getDefaultValue(key);

        if (isEnabled) {
          await _firebaseMessaging.subscribeToTopic(key);
          print('Subscribed to topic: $key');
        } else {
          await _firebaseMessaging.unsubscribeFromTopic(key);
          print('Unsubscribed from topic: $key');
        }
      }
    } catch (e) {
      print('Error managing topic subscriptions: $e');
    }
  }

  static bool _getDefaultValue(String key) {
    // Match your UI default values
    switch (key) {
      case 'promotions':
      case 'new_features':
        return false;
      default:
        return true;
    }
  }

  static Future<bool> _isNotificationEnabled(String type) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notification_$type') ?? _getDefaultValue(type);
    } catch (e) {
      print('Error checking notification preference: $e');
      return _getDefaultValue(type);
    }
  }

  static Future<void> updateNotificationPreference(String key, bool enabled) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_$key', enabled);

      // Subscribe or unsubscribe from topic
      if (enabled) {
        await _firebaseMessaging.subscribeToTopic(key);
        print('Subscribed to topic: $key');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic(key);
        print('Unsubscribed from topic: $key');
      }
    } catch (e) {
      print('Error updating notification preference: $e');
    }
  }

  // Method to handle navigation from outside the service
  static void setNavigationHandler(Function(Map<String, dynamic>) handler) {
    onNotificationTapped = handler;
  }

  // Method to clear notification badge (iOS)
  static Future<void> clearBadge() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Method to get notification count or manage badge
  static Future<void> setBadgeCount(int count) async {
    // This would require additional plugins for badge management
    // You can use flutter_app_badger plugin for this
  }
}

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("Background message data: ${message.data}");
  // You can add custom logic here for background processing
}