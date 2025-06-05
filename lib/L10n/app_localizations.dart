// File: lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Common
  String get appTitle => _localizedValues[locale.languageCode]?['app_title'] ?? 'BANQUETBOOKZ-U';
  String get loading => _localizedValues[locale.languageCode]?['loading'] ?? 'Loading...';
  String get error => _localizedValues[locale.languageCode]?['error'] ?? 'Error';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get ok => _localizedValues[locale.languageCode]?['ok'] ?? 'OK';
  String get yes => _localizedValues[locale.languageCode]?['yes'] ?? 'Yes';
  String get no => _localizedValues[locale.languageCode]?['no'] ?? 'No';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get retry => _localizedValues[locale.languageCode]?['retry'] ?? 'Retry';
  String get close => _localizedValues[locale.languageCode]?['close'] ?? 'Close';

  // Settings Screen
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get account => _localizedValues[locale.languageCode]?['account'] ?? 'Account';
  String get profileSettings => _localizedValues[locale.languageCode]?['profile_settings'] ?? 'Profile Settings';
  String get wallet => _localizedValues[locale.languageCode]?['wallet'] ?? 'Wallet';
  String get paymentHistory => _localizedValues[locale.languageCode]?['payment_history'] ?? 'Payment History';
  String get preferences => _localizedValues[locale.languageCode]?['preferences'] ?? 'Preferences';
  String get notificationSettings => _localizedValues[locale.languageCode]?['notification_settings'] ?? 'Notification Settings';
  String get languages => _localizedValues[locale.languageCode]?['languages'] ?? 'Languages';
  String get themes => _localizedValues[locale.languageCode]?['themes'] ?? 'Themes';
  String get leaveReview => _localizedValues[locale.languageCode]?['leave_review'] ?? 'Leave Review';
  String get support => _localizedValues[locale.languageCode]?['support'] ?? 'Support';
  String get helpCenter => _localizedValues[locale.languageCode]?['help_center'] ?? 'Help Center';
  String get contactSupport => _localizedValues[locale.languageCode]?['contact_support'] ?? 'Contact Support';
  String get privacyPolicy => _localizedValues[locale.languageCode]?['privacy_policy'] ?? 'Privacy Policy';
  String get termsOfService => _localizedValues[locale.languageCode]?['terms_of_service'] ?? 'Terms of Service';
  String get session => _localizedValues[locale.languageCode]?['session'] ?? 'Session';
  String get deleteAccount => _localizedValues[locale.languageCode]?['delete_account'] ?? 'Delete Account';
  String get logout => _localizedValues[locale.languageCode]?['logout'] ?? 'Logout';

  // Language Selection
  String get selectLanguage => _localizedValues[locale.languageCode]?['select_language'] ?? 'Select Language';
  String get languageChanged => _localizedValues[locale.languageCode]?['language_changed'] ?? 'Language changed to';

  // Theme Selection
  String get selectTheme => _localizedValues[locale.languageCode]?['select_theme'] ?? 'Select Theme';
  String get light => _localizedValues[locale.languageCode]?['light'] ?? 'Light';
  String get dark => _localizedValues[locale.languageCode]?['dark'] ?? 'Dark';
  String get systemDefault => _localizedValues[locale.languageCode]?['system_default'] ?? 'System Default';
  String get themeChanged => _localizedValues[locale.languageCode]?['theme_changed'] ?? 'Theme changed to';

  // Delete Account
  String get deleteAccountTitle => _localizedValues[locale.languageCode]?['delete_account_title'] ?? 'Delete Account';
  String get deleteAccountWarning => _localizedValues[locale.languageCode]?['delete_account_warning'] ??
      'Warning: This action will permanently delete your account and all associated data. This action cannot be undone. Are you sure you want to proceed?';
  String get accountDeletedSuccess => _localizedValues[locale.languageCode]?['account_deleted_success'] ??
      'Your account has been deleted successfully';
  String get failedToDeleteAccount => _localizedValues[locale.languageCode]?['failed_to_delete_account'] ??
      'Failed to delete account';

  // Home Screen
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Home';
  String get venues => _localizedValues[locale.languageCode]?['venues'] ?? 'Venues';
  String get bookings => _localizedValues[locale.languageCode]?['bookings'] ?? 'Bookings';
  String get upcomingBookings => _localizedValues[locale.languageCode]?['upcoming_bookings'] ?? 'Upcoming Bookings';
  String get manageBooking => _localizedValues[locale.languageCode]?['manage_booking'] ?? 'Manage Booking';

  // Home Screen - App Bar
  String get welcomeBack => _localizedValues[locale.languageCode]?['welcome_back'] ?? 'Welcome back';
  String get guest => _localizedValues[locale.languageCode]?['guest'] ?? 'Guest';

  // Home Screen - Search
  String get searchVenuesHalls => _localizedValues[locale.languageCode]?['search_venues_halls'] ?? 'Search for venues, halls...';

  // Home Screen - Quick Access
  String get quickAccess => _localizedValues[locale.languageCode]?['quick_access'] ?? 'Quick Access';
  String get myBookings => _localizedValues[locale.languageCode]?['my_bookings'] ?? 'My Bookings';
  String get wallets => _localizedValues[locale.languageCode]?['wallets'] ?? 'Wallets';

  // Home Screen - Properties
  String get newlyAdded => _localizedValues[locale.languageCode]?['newly_added'] ?? 'Newly Added';
  String get viewAll => _localizedValues[locale.languageCode]?['view_all'] ?? 'View All';
  String get viewDetails => _localizedValues[locale.languageCode]?['view_details'] ?? 'View Details';
  String get noVenuesAvailable => _localizedValues[locale.languageCode]?['no_venues_available'] ?? 'No venues available yet';
  String get exploreVenues => _localizedValues[locale.languageCode]?['explore_venues'] ?? 'Explore Venues';
  String get noName => _localizedValues[locale.languageCode]?['no_name'] ?? 'No Name';
  String get noAddress => _localizedValues[locale.languageCode]?['no_address'] ?? 'No Address';

  // Home Screen - Reviews
  String get recentReviews => _localizedValues[locale.languageCode]?['recent_reviews'] ?? 'Recent Reviews';
  String get refreshReviews => _localizedValues[locale.languageCode]?['refresh_reviews'] ?? 'Refresh Reviews';
  String get unknownVenue => _localizedValues[locale.languageCode]?['unknown_venue'] ?? 'Unknown Venue';
  String get property => _localizedValues[locale.languageCode]?['property'] ?? 'Property';
  String get hall => _localizedValues[locale.languageCode]?['hall'] ?? 'Hall';
  String get userId => _localizedValues[locale.languageCode]?['user_id'] ?? 'User ID';
  String get reviewDetails => _localizedValues[locale.languageCode]?['review_details'] ?? 'Review Details';
  String get venue => _localizedValues[locale.languageCode]?['venue'] ?? 'Venue';
  String get type => _localizedValues[locale.languageCode]?['type'] ?? 'Type';
  String get rating => _localizedValues[locale.languageCode]?['rating'] ?? 'Rating';
  String get review => _localizedValues[locale.languageCode]?['review'] ?? 'Review';
  String get errorLoadingReviews => _localizedValues[locale.languageCode]?['error_loading_reviews'] ?? 'Error loading reviews';
  String get noReviewsAvailable => _localizedValues[locale.languageCode]?['no_reviews_available'] ?? 'No reviews available yet';
  String get writeReview => _localizedValues[locale.languageCode]?['write_review'] ?? 'Write a Review';

  // Notification messages
  String get viewingBookingDetails => _localizedValues[locale.languageCode]?['viewing_booking_details'] ?? 'Viewing booking details';
  String get viewingUpcomingBookings => _localizedValues[locale.languageCode]?['viewing_upcoming_bookings'] ?? 'Viewing upcoming bookings';
  String get viewingPaymentHistory => _localizedValues[locale.languageCode]?['viewing_payment_history'] ?? 'Viewing payment history';
  String get timeToLeaveReview => _localizedValues[locale.languageCode]?['time_to_leave_review'] ?? 'Time to leave a review!';
  String get checkOutPromotions => _localizedValues[locale.languageCode]?['check_out_promotions'] ?? 'Check out new promotions!';
  String get systemUpdatesAvailable => _localizedValues[locale.languageCode]?['system_updates_available'] ?? 'System updates available';
  String get bookingCancellationDetails => _localizedValues[locale.languageCode]?['booking_cancellation_details'] ?? 'Booking cancellation details';
  String get openedFromNotification => _localizedValues[locale.languageCode]?['opened_from_notification'] ?? 'Opened from notification';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'BANQUETBOOKZ-U',
      'loading': 'Loading...',
      'error': 'Error',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'save': 'Save',
      'delete': 'Delete',
      'retry': 'Retry',
      'close': 'Close',
      'settings': 'Settings',
      'account': 'Account',
      'profile_settings': 'Profile Settings',
      'wallet': 'Wallet',
      'payment_history': 'Payment History',
      'preferences': 'Preferences',
      'notification_settings': 'Notification Settings',
      'languages': 'Languages',
      'themes': 'Themes',
      'leave_review': 'Leave Review',
      'support': 'Support',
      'help_center': 'Help Center',
      'contact_support': 'Contact Support',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'session': 'Session',
      'delete_account': 'Delete Account',
      'logout': 'Logout',
      'select_language': 'Select Language',
      'language_changed': 'Language changed to',
      'select_theme': 'Select Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system_default': 'System Default',
      'theme_changed': 'Theme changed to',
      'delete_account_title': 'Delete Account',
      'delete_account_warning': 'Warning: This action will permanently delete your account and all associated data. This action cannot be undone. Are you sure you want to proceed?',
      'account_deleted_success': 'Your account has been deleted successfully',
      'failed_to_delete_account': 'Failed to delete account',
      'home': 'Home',
      'venues': 'Venues',
      'bookings': 'Bookings',
      'upcoming_bookings': 'Upcoming Bookings',
      'manage_booking': 'Manage Booking',
      'welcome_back': 'Welcome back',
      'guest': 'Guest',
      'search_venues_halls': 'Search for venues, halls...',
      'quick_access': 'Quick Access',
      'my_bookings': 'My Bookings',
      'wallets': 'Wallets',
      'newly_added': 'Newly Added',
      'view_all': 'View All',
      'view_details': 'View Details',
      'no_venues_available': 'No venues available yet',
      'explore_venues': 'Explore Venues',
      'no_name': 'No Name',
      'no_address': 'No Address',
      'recent_reviews': 'Recent Reviews',
      'refresh_reviews': 'Refresh Reviews',
      'unknown_venue': 'Unknown Venue',
      'property': 'Property',
      'hall': 'Hall',
      'user_id': 'User ID',
      'review_details': 'Review Details',
      'venue': 'Venue',
      'type': 'Type',
      'rating': 'Rating',
      'review': 'Review',
      'error_loading_reviews': 'Error loading reviews',
      'no_reviews_available': 'No reviews available yet',
      'write_review': 'Write a Review',
      'viewing_booking_details': 'Viewing booking details',
      'viewing_upcoming_bookings': 'Viewing upcoming bookings',
      'viewing_payment_history': 'Viewing payment history',
      'time_to_leave_review': 'Time to leave a review!',
      'check_out_promotions': 'Check out new promotions!',
      'system_updates_available': 'System updates available',
      'booking_cancellation_details': 'Booking cancellation details',
      'opened_from_notification': 'Opened from notification',
    },
    'te': {
      'app_title': 'బ్యాంక్వెట్‌బుక్స్-యు',
      'loading': 'లోడ్ అవుతోంది...',
      'error': 'లోపం',
      'cancel': 'రద్దు',
      'ok': 'సరే',
      'yes': 'అవును',
      'no': 'లేదు',
      'save': 'సేవ్',
      'delete': 'తొలగించు',
      'retry': 'మళ్లీ ప్రయత్నించు',
      'close': 'మూసివేయు',
      'settings': 'సెట్టింగ్స్',
      'account': 'ఖాతా',
      'profile_settings': 'ప్రొఫైల్ సెట్టింగ్స్',
      'wallet': 'వాలెట్',
      'payment_history': 'చెల్లింపు చరిత్ర',
      'preferences': 'ప్రాధాన్యతలు',
      'notification_settings': 'నోటిఫికేషన్ సెట్టింగ్స్',
      'languages': 'భాషలు',
      'themes': 'థీమ్‌లు',
      'leave_review': 'రివ్యూ ఇవ్వండి',
      'support': 'మద్దతు',
      'help_center': 'సహాయ కేంద్రం',
      'contact_support': 'మద్దతును సంప్రదించండి',
      'privacy_policy': 'గోప్యతా విధానం',
      'terms_of_service': 'సేవా నియమాలు',
      'session': 'సెషన్',
      'delete_account': 'ఖాతాను తొలగించు',
      'logout': 'లాగ్ అవుట్',
      'select_language': 'భాష ఎంచుకోండი',
      'language_changed': 'భాష మార్చబడింది',
      'select_theme': 'థీమ్ ఎంచుకోండి',
      'light': 'లైట్',
      'dark': 'డార్క్',
      'system_default': 'సిస్టమ్ డిఫాల్ట్',
      'theme_changed': 'థీమ్ మార్చబడింది',
      'delete_account_title': 'ఖాతాను తొలగించు',
      'delete_account_warning': 'హెచ్చరిక: ఈ చర్య మీ ఖాతా మరియు అన్ని సంబంధిత డేటాను శాశ్వతంగా తొలగిస్తుంది. ఈ చర్యను రద్దు చేయలేము. మీరు ఖచ్చితంగా కొనసాగించాలనుకుంటున్నారా?',
      'account_deleted_success': 'మీ ఖాతా విజయవంతంగా తొలగించబడింది',
      'failed_to_delete_account': 'ఖాతాను తొలగించడంలో విఫలమైంది',
      'home': 'హోమ్',
      'venues': 'వేదికలు',
      'bookings': 'బుకింగ్‌లు',
      'upcoming_bookings': 'రాబోయే బుకింగ్‌లు',
      'manage_booking': 'బుకింగ్ నిర్వహించండి',
      'welcome_back': 'మళ్లీ స్వాగతం',
      'guest': 'అతిథి',
      'search_venues_halls': 'వేదికలు, హాల్స్ కోసం వెతకండి...',
      'quick_access': 'త్వరిత యాక్సెస్',
      'my_bookings': 'నా బుకింగ్‌లు',
      'wallets': 'వాలెట్‌లు',
      'newly_added': 'కొత్తగా జోడించబడినవి',
      'view_all': 'అన్నీ చూడండి',
      'view_details': 'వివరాలు చూడండి',
      'no_venues_available': 'ఇంకా వేదికలు అందుబాటులో లేవు',
      'explore_venues': 'వేదికలను అన్వేషించండి',
      'no_name': 'పేరు లేదు',
      'no_address': 'చిరునామా లేదు',
      'recent_reviews': 'ఇటీవలి రివ్యూలు',
      'refresh_reviews': 'రివ్యూలను రీఫ్రెష్ చేయండి',
      'unknown_venue': 'తెలియని వేదిక',
      'property': 'ప్రాపర్టీ',
      'hall': 'హాల్',
      'user_id': 'యూజర్ ID',
      'review_details': 'రివ్యూ వివరాలు',
      'venue': 'వేదిక',
      'type': 'రకం',
      'rating': 'రేటింగ్',
      'review': 'రివ్యూ',
      'error_loading_reviews': 'రివ్యూలు లోడ్ చేయడంలో లోపం',
      'no_reviews_available': 'ఇంకా రివ్యూలు అందుబాటులో లేవు',
      'write_review': 'రివ్యూ రాయండి',
      'viewing_booking_details': 'బుకింగ్ వివరాలను చూస్తున్నారు',
      'viewing_upcoming_bookings': 'రాబోయే బుకింగ్‌లను చూస్తున్నారు',
      'viewing_payment_history': 'చెల్లింపు చరిత్రను చూస్తున్నారు',
      'time_to_leave_review': 'రివ్యూ ఇవ్వడానికి సమయం!',
      'check_out_promotions': 'కొత్త ప్రమోషన్‌లను చూడండి!',
      'system_updates_available': 'సిస్టమ్ అప్‌డేట్‌లు అందుబాటులో ఉన్నాయి',
      'booking_cancellation_details': 'బుకింగ్ రద్దు వివరాలు',
      'opened_from_notification': 'నోటిఫికేషన్ నుండి తెరవబడింది',
    },
    'hi': {
      'app_title': 'बैंक्वेटबुक्स-यू',
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'cancel': 'रद्द करें',
      'ok': 'ठीक है',
      'yes': 'हाँ',
      'no': 'नहीं',
      'save': 'सेव करें',
      'delete': 'हटाएं',
      'retry': 'पुनः प्रयास करें',
      'close': 'बंद करें',
      'settings': 'सेटिंग्स',
      'account': 'खाता',
      'profile_settings': 'प्रोफाइल सेटिंग्स',
      'wallet': 'वॉलेट',
      'payment_history': 'भुगतान इतिहास',
      'preferences': 'वरीयताएं',
      'notification_settings': 'नोटिफिकेशन सेटिंग्स',
      'languages': 'भाषाएं',
      'themes': 'थीम',
      'leave_review': 'समीक्षा दें',
      'support': 'सहायता',
      'help_center': 'सहायता केंद्र',
      'contact_support': 'सहायता से संपर्क करें',
      'privacy_policy': 'गोपनीयता नीति',
      'terms_of_service': 'सेवा की शर्तें',
      'session': 'सत्र',
      'delete_account': 'खाता हटाएं',
      'logout': 'लॉग आउट',
      'select_language': 'भाषा चुनें',
      'language_changed': 'भाषा बदली गई',
      'select_theme': 'थीम चुनें',
      'light': 'लाइट',
      'dark': 'डार्क',
      'system_default': 'सिस्टम डिफ़ॉल्ट',
      'theme_changed': 'थीम बदली गई',
      'delete_account_title': 'खाता हटाएं',
      'delete_account_warning': 'चेतावनी: यह क्रिया आपके खाते और सभी संबंधित डेटा को स्थायी रूप से हटा देगी। इस क्रिया को पूर्ववत नहीं किया जा सकता। क्या आप वाकई जारी रखना चाहते हैं?',
      'account_deleted_success': 'आपका खाता सफलतापूर्वक हटा दिया गया है',
      'failed_to_delete_account': 'खाता हटाने में विफल',
      'home': 'होम',
      'venues': 'स्थान',
      'bookings': 'बुकिंग',
      'upcoming_bookings': 'आगामी बुकिंग',
      'manage_booking': 'बुकिंग प्रबंधित करें',
      'welcome_back': 'वापसी पर स्वागत है',
      'guest': 'अतिथि',
      'search_venues_halls': 'स्थान, हॉल खोजें...',
      'quick_access': 'त्वरित पहुंच',
      'my_bookings': 'मेरी बुकिंग',
      'wallets': 'वॉलेट',
      'newly_added': 'हाल ही में जोड़े गए',
      'view_all': 'सभी देखें',
      'view_details': 'विवरण देखें',
      'no_venues_available': 'अभी तक कोई स्थान उपलब्ध नहीं है',
      'explore_venues': 'स्थानों का अन्वेषण करें',
      'no_name': 'कोई नाम नहीं',
      'no_address': 'कोई पता नहीं',
      'recent_reviews': 'हाल की समीक्षाएं',
      'refresh_reviews': 'समीक्षाएं रीफ्रेश करें',
      'unknown_venue': 'अज्ञात स्थान',
      'property': 'संपत्ति',
      'hall': 'हॉल',
      'user_id': 'यूजर ID',
      'review_details': 'समीक्षा विवरण',
      'venue': 'स्थान',
      'type': 'प्रकार',
      'rating': 'रेटिंग',
      'review': 'समीक्षा',
      'error_loading_reviews': 'समीक्षाएं लोड करने में त्रुटि',
      'no_reviews_available': 'अभी तक कोई समीक्षा उपलब्ध नहीं है',
      'write_review': 'समीक्षा लिखें',
      'viewing_booking_details': 'बुकिंग विवरण देख रहे हैं',
      'viewing_upcoming_bookings': 'आगामी बुकिंग देख रहे हैं',
      'viewing_payment_history': 'भुगतान इतिहास देख रहे हैं',
      'time_to_leave_review': 'समीक्षा देने का समय!',
      'check_out_promotions': 'नए प्रमोशन देखें!',
      'system_updates_available': 'सिस्टम अपडेट उपलब्ध हैं',
      'booking_cancellation_details': 'बुकिंग रद्दीकरण विवरण',
      'opened_from_notification': 'नोटिफिकेशन से खोला गया',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'te', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}