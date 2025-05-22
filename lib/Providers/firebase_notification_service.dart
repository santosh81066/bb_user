import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class EnhancedFirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Function(Map<String, dynamic>)? onNotificationTapped;

  // Enhanced notification control states
  static const String NOTIFICATIONS_MASTER_KEY = 'notifications_master_enabled';
  static const String NOTIFICATIONS_PERMISSION_KEY = 'notifications_permission_granted';
  static const String NOTIFICATIONS_FIRST_TIME_KEY = 'notifications_first_time_setup';

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

  // Time-based controls
  static const String QUIET_HOURS_ENABLED_KEY = 'quiet_hours_enabled';
  static const String QUIET_HOURS_START_KEY = 'quiet_hours_start';
  static const String QUIET_HOURS_END_KEY = 'quiet_hours_end';

  /// Initialize notification service with enhanced controls
  static Future<bool> initialize() async {
    try {
      // Check if this is first time setup
      bool? isFirstTime = await _isFirstTimeSetup();

    /*  if (isFirstTime) {
        // Show permission dialog and setup
        bool permissionGranted = await requestPermissionWithDialog();
        if (!permissionGranted) {
          await _setMasterNotificationEnabled(false);
          return false;
        }
        await _setFirstTimeSetupComplete();
      }*/

      // Check master notification setting
      bool masterEnabled = await isMasterNotificationEnabled();
      if (!masterEnabled) {
        print('Master notifications disabled, skipping initialization');
        return false;
      }

      // Check system-level permissions
      bool hasPermission = await checkSystemPermissions();
      if (!hasPermission) {
        await _setMasterNotificationEnabled(false);
        return false;
      }

      await _initializeFirebaseMessaging();
      await _initializeLocalNotifications();
      await _setupMessageHandlers();
      await _subscribeToTopics();

      print('Enhanced Firebase Notification Service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing Enhanced Firebase Notification Service: $e');
      return false;
    }
  }

  /// Check if user has granted system-level notification permissions
  static Future<bool> checkSystemPermissions() async {
    try {
      // For Android 13+ (API 33+)
      var status = await Permission.notification.status;

      if (status.isDenied) {
        // Permission not yet requested
        return false;
      } else if (status.isPermanentlyDenied) {
        // User permanently denied permission
        await _setPermissionStatus(false);
        return false;
      } else if (status.isGranted) {
        await _setPermissionStatus(true);
        return true;
      }

      // For iOS, check Firebase permission status
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      bool iosPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      await _setPermissionStatus(iosPermission);
      return iosPermission;
    } catch (e) {
      print('Error checking system permissions: $e');
      return false;
    }
  }

  /// Request permission with custom dialog
  static Future<bool> requestPermissionWithDialog() async {
    try {
      // For Android 13+
      if (await Permission.notification.isDenied) {
        PermissionStatus status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          return false;
        }
      }

      // For iOS and general Firebase setup
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      bool granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      await _setPermissionStatus(granted);
      await _setMasterNotificationEnabled(granted);

      return granted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Open system settings for notification permissions
  static Future<bool> openNotificationSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('Error opening notification settings: $e');
      return false;
    }
  }

  /// Master control - Enable/Disable all notifications
  static Future<void> setMasterNotificationEnabled(bool enabled) async {
    await _setMasterNotificationEnabled(enabled);

    if (enabled) {
      // Check if we have permission first
      bool hasPermission = await checkSystemPermissions();
      if (!hasPermission) {
        // Request permission
        bool granted = await requestPermissionWithDialog();
        if (!granted) {
          await _setMasterNotificationEnabled(false);
          return;
        }
      }

      // Re-initialize and subscribe to topics
      await _subscribeToTopics();
    } else {
      // Unsubscribe from all topics
      await _unsubscribeFromAllTopics();
    }
  }

  /// Check if master notifications are enabled
  static Future<bool> isMasterNotificationEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NOTIFICATIONS_MASTER_KEY) ?? true;
  }

  /// Enhanced message filtering with multiple control layers
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Layer 1: Master notification check
    if (!await isMasterNotificationEnabled()) {
      print('Master notifications disabled, skipping');
      return;
    }

    // Layer 2: System permission check
    if (!await checkSystemPermissions()) {
      print('System permissions not granted, skipping');
      return;
    }

    // Layer 3: Quiet hours check
    if (await _isInQuietHours()) {
      print('Currently in quiet hours, skipping notification');
      return;
    }

    // Layer 4: Specific notification type check
    String? notificationType = message.data['type'];
    if (notificationType != null && !await _isNotificationEnabled(notificationType)) {
      print('Notification type $notificationType is disabled, skipping');
      return;
    }

    // Layer 5: Priority/importance filtering
    if (await _shouldFilterByPriority(message)) {
      print('Notification filtered by priority settings');
      return;
    }

    await _showLocalNotification(message);
  }

  /// Quiet hours functionality
  static Future<void> setQuietHours(bool enabled, TimeOfDay? start, TimeOfDay? end) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(QUIET_HOURS_ENABLED_KEY, enabled);

    if (enabled && start != null && end != null) {
      await prefs.setString(QUIET_HOURS_START_KEY, '${start.hour}:${start.minute}');
      await prefs.setString(QUIET_HOURS_END_KEY, '${end.hour}:${end.minute}');
    }
  }

  static Future<bool> _isInQuietHours() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool enabled = prefs.getBool(QUIET_HOURS_ENABLED_KEY) ?? false;

      if (!enabled) return false;

      String? startStr = prefs.getString(QUIET_HOURS_START_KEY);
      String? endStr = prefs.getString(QUIET_HOURS_END_KEY);

      if (startStr == null || endStr == null) return false;

      List<String> startParts = startStr.split(':');
      List<String> endParts = endStr.split(':');

      TimeOfDay start = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      TimeOfDay end = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

      TimeOfDay now = TimeOfDay.now();

      // Convert to minutes for easier comparison
      int nowMinutes = now.hour * 60 + now.minute;
      int startMinutes = start.hour * 60 + start.minute;
      int endMinutes = end.hour * 60 + end.minute;

      if (startMinutes <= endMinutes) {
        // Same day range
        return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      } else {
        // Overnight range
        return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      }
    } catch (e) {
      print('Error checking quiet hours: $e');
      return false;
    }
  }

  /// Priority-based filtering
  static Future<bool> _shouldFilterByPriority(RemoteMessage message) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String priority = message.data['priority'] ?? 'normal';

      // Get user's minimum priority setting
      String minPriority = prefs.getString('notification_min_priority') ?? 'low';

      Map<String, int> priorityLevels = {
        'low': 1,
        'normal': 2,
        'high': 3,
        'urgent': 4,
      };

      int messagePriority = priorityLevels[priority] ?? 2;
      int minRequiredPriority = priorityLevels[minPriority] ?? 1;

      return messagePriority < minRequiredPriority;
    } catch (e) {
      print('Error filtering by priority: $e');
      return false;
    }
  }

  /// Set minimum notification priority
  static Future<void> setMinimumNotificationPriority(String priority) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_min_priority', priority);
  }

  /// Enhanced topic management with user control
  static Future<void> updateNotificationPreference(String key, bool enabled) async {
    try {
      // Check master setting first
      if (!await isMasterNotificationEnabled()) {
        print('Master notifications disabled, not updating topic subscription');
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_$key', enabled);

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

  /// Get comprehensive notification status
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      'masterEnabled': await isMasterNotificationEnabled(),
      'systemPermission': await checkSystemPermissions(),
      'quietHoursEnabled': prefs.getBool(QUIET_HOURS_ENABLED_KEY) ?? false,
      'quietHoursStart': prefs.getString(QUIET_HOURS_START_KEY),
      'quietHoursEnd': prefs.getString(QUIET_HOURS_END_KEY),
      'minPriority': prefs.getString('notification_min_priority') ?? 'low',
      'fcmToken': await getToken(),
      'topicSubscriptions': await _getTopicSubscriptions(),
    };
  }

  static Future<Map<String, bool>> _getTopicSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, bool> subscriptions = {};

    for (String key in notificationTypes.keys) {
      subscriptions[key] = prefs.getBool('notification_$key') ?? _getDefaultValue(key);
    }

    return subscriptions;
  }

  /// Utility methods
  static Future<void> _setMasterNotificationEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NOTIFICATIONS_MASTER_KEY, enabled);
  }

  static Future<void> _setPermissionStatus(bool granted) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NOTIFICATIONS_PERMISSION_KEY, granted);
  }

  static Future<bool?> _isFirstTimeSetup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(NOTIFICATIONS_FIRST_TIME_KEY,);
  }

  static Future<void> _setFirstTimeSetupComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NOTIFICATIONS_FIRST_TIME_KEY, true);
  }

  static Future<void> _unsubscribeFromAllTopics() async {
    for (String key in notificationTypes.keys) {
      try {
        await _firebaseMessaging.unsubscribeFromTopic(key);
        print('Unsubscribed from topic: $key');
      } catch (e) {
        print('Error unsubscribing from topic $key: $e');
      }
    }
  }

  // Include your existing methods here...
  static Future<void> _initializeFirebaseMessaging() async {
    // Your existing Firebase initialization code
  }

  static Future<void> _initializeLocalNotifications() async {
    // Your existing local notification initialization code
  }

  static Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _subscribeToTopics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (String key in notificationTypes.keys) {
      bool isEnabled = prefs.getBool('notification_$key') ?? _getDefaultValue(key);

      if (isEnabled) {
        await _firebaseMessaging.subscribeToTopic(key);
        print('Subscribed to topic: $key');
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // Your existing local notification display code
  }

  static void _handleNotificationTap(RemoteMessage message) async {
    // Your existing notification tap handling code
  }

  static Future<bool> _isNotificationEnabled(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_$type') ?? _getDefaultValue(type);
  }

  static bool _getDefaultValue(String key) {
    switch (key) {
      case 'promotions':
      case 'new_features':
        return false;
      default:
        return true;
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}