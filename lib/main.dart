import 'package:bb_user/Providers/firebase_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Colors/coustcolors.dart';
import 'Providers/auth.dart';
import 'Screens/contactsupportpage.dart';
import 'Screens/hallscalendar.dart';
import 'Screens/helpcenterpage.dart';
import 'Screens/home.dart';
import 'Screens/location.dart';
import 'Screens/login.dart';
import 'Screens/managebooking.dart';
import 'Screens/notificationsettings.dart';
import 'Screens/paymenthistory.dart';
import 'Screens/paymentpage.dart';
import 'Screens/profilesettings.dart';
import 'Screens/registration.dart';
import 'Screens/review.dart';
import 'Screens/settings.dart';
import 'Screens/upcoming.dart';
import 'Screens/walletscreen.dart';
import 'Widgets/bottomnavigation.dart';
import 'firebase_options.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize notification service with proper error handling
    bool notificationInitialized = await EnhancedFirebaseNotificationService.initialize();
    if (notificationInitialized) {
      print('Notification service initialized successfully');
    } else {
      print('Notification service initialization failed or disabled');
    }

    // Set up notification navigation handler
    /*EnhancedFirebaseNotificationService.setNavigationHandler(_handleNotificationNavigation);*/



    // Try to sign in anonymously on app start
    final FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print('Anonymous auth successful on app start');
    } else {
      print('Already authenticated: ${auth.currentUser!.uid}');
    }
  } catch (e) {
    print('Error during Firebase initialization: $e');
    // Don't throw here - let the app continue even if Firebase fails
  }
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  print('Handling notification navigation: $data');

  String? type = data['type'];
  String? screen = data['screen'];
  String? bookingId = data['booking_id'];
  String? userId = data['user_id'];

  // Get current context
  BuildContext? context = navigatorKey.currentContext;
  if (context == null) {
    print('No navigation context available');
    return;
  }

  // Add a small delay to ensure the app is fully loaded
  Future.delayed(Duration(milliseconds: 500), () {
    try {
      switch (type) {
        case 'booking':
          if (bookingId != null) {
            // Navigate to specific booking details with arguments
            Navigator.pushNamed(
                context,
                '/manage_booking',
                arguments: {
                  'bookingId': bookingId,
                  'fromNotification': true,
                }
            );
          } else {
            Navigator.pushNamed(context, '/manage_booking');
          }
          break;

        case 'upcoming':
          Navigator.pushNamed(
              context,
              '/upcoming_booking',
              arguments: {
                'fromNotification': true,
                'bookingId': bookingId,
              }
          );
          break;

        case 'payment_confirmations':
          if (bookingId != null) {
            Navigator.pushNamed(
                context,
                '/payment_history',
                arguments: {
                  'bookingId': bookingId,
                  'fromNotification': true,
                }
            );
          } else {
            Navigator.pushNamed(context, '/payment_history');
          }
          break;

        case 'reviews':
          Navigator.pushNamed(
              context,
              '/review',
              arguments: {
                'fromNotification': true,
                'bookingId': bookingId,
              }
          );
          break;

        case 'promotions':
        case 'new_features':
          Navigator.pushNamed(
              context,
              '/home',
              arguments: {
                'fromNotification': true,
                'notificationType': type,
              }
          );
          break;

        case 'system_updates':
          Navigator.pushNamed(
              context,
              '/settings',
              arguments: {
                'fromNotification': true,
                'highlightUpdates': true,
              }
          );
          break;

        case 'cancellations':
          Navigator.pushNamed(
              context,
              '/manage_booking',
              arguments: {
                'fromNotification': true,
                'bookingId': bookingId,
                'showCancelled': true,
              }
          );
          break;

        default:
        // If screen is specified, navigate to that screen
          if (screen != null) {
            Navigator.pushNamed(context, screen);
          } else {
            // Default to home with notification flag
            Navigator.pushNamed(
                context,
                '/home',
                arguments: {
                  'fromNotification': true,
                }
            );
          }
          break;
      }

      // Show a subtle indicator that user came from notification
      _showNotificationIndicator(context, type);

    } catch (e) {
      print('Error navigating from notification: $e');
      // Fallback to home screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
        arguments: {'fromNotification': true, 'error': true},
      );
    }
  });
}

void _showNotificationIndicator(BuildContext context, String? type) {
  // Show a subtle snackbar to indicate the user came from a notification
  String message = 'Opened from notification';

  switch (type) {
    case 'booking':
      message = 'Viewing booking details';
      break;
    case 'upcoming':
      message = 'Viewing upcoming bookings';
      break;
    case 'payment_confirmations':
      message = 'Viewing payment history';
      break;
    case 'reviews':
      message = 'Time to leave a review!';
      break;
    case 'promotions':
      message = 'Check out new promotions!';
      break;
    case 'system_updates':
      message = 'System updates available';
      break;
    case 'cancellations':
      message = 'Booking cancellation details';
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.notifications, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(message),
        ],
      ),
      backgroundColor: Color(0xFF6418C3),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
    ),
  );
}

void main() async {
  // Initialize Firebase before running the app
  await initializeFirebase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BANQUETBOOKZ-U',
      navigatorKey: navigatorKey, // Essential for notification navigation
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF6418C3),
        ),
        scaffoldBackgroundColor: CoustColors.colrButton3,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF6418C3),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: CoustColors.colrButton3,
          unselectedItemColor: CoustColors.colrSubText,
        ),
        // Add snackbar theme for notification indicators
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6418C3),
        ),
      ),
      routes: {
        '/': (context) {
          return Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authprovider);

              if (authState.token != null) {
                return ResponsiveNavigation();
              }

              return _AuthCheckScreen();
            },
          );
        },
        '/registration': (BuildContext context) {
          return const RegistrationScreen();
        },
        '/welcome': (BuildContext context) {
          return ResponsiveNavigation();
        },
        '/profile_settings': (BuildContext context) {
          return const ProfileSetingsScreen();
        },
        '/payment_history': (BuildContext context) {
          return const PaymentHistoryScreen();
        },
        '/notification_settings': (BuildContext context) {
          return NotificationSettingsScreen();
        },
        '/contact support': (BuildContext context) {
          return ContactSupportPage();
        },
        '/help center': (BuildContext context) {
          return HelpCenterPage();
        },
        '/manage_booking': (BuildContext context) {
          return const ManageBookingScreen();
        },
        '/upcoming_booking': (BuildContext context) {
          return const UpcomingbookingsScreen();
        },
        '/wallet': (BuildContext context) {
          return const WalletScreen();
        },
        '/location': (BuildContext context) {
          return const LocationScreen();
        },
        '/venue_details': (BuildContext context) {
          return const HallsCalendarScreen();
        },
        '/payment': (BuildContext context) {
          return const PaymentPage();
        },
        '/home': (BuildContext context) {
          return const HomeScreen();
        },
        '/settings': (BuildContext context) {
          return const SettingsScreen();
        },
        '/review': (BuildContext context) {
          return const ReviewPage();
        },
      },
      // Handle unknown routes
      onUnknownRoute: (settings) {
        print('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: RouteSettings(
            name: '/home',
            arguments: {'error': 'Unknown route: ${settings.name}'},
          ),
        );
      },
    );
  }
}

class _AuthCheckScreen extends ConsumerStatefulWidget {
  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<_AuthCheckScreen> {
  late Future<bool> _authCheckFuture;

  @override
  void initState() {
    super.initState();
    _authCheckFuture = ref.read(authprovider.notifier).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color(0xFF6418C3),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png', // Add your app logo
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Icon(
                          Icons.event,
                          size: 60,
                          color: Color(0xFF6418C3),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return snapshot.data == true
              ? ResponsiveNavigation()
              : const ResponsiveLoginScreen();
        }
      },
    );
  }
}

//////////////////////////////////////////////////////////

// // import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import 'Colors/coustcolors.dart';
// import 'Providers/auth.dart';
// import 'Screens/hallscalendar.dart';
// import 'Screens/home.dart';
// import 'Screens/location.dart';
// import 'Screens/login.dart';
// import 'Screens/managebooking.dart';
// import 'Screens/notificationsettings.dart';
// import 'Screens/paymenthistory.dart';
// import 'Screens/profilesettings.dart';
// import 'Screens/registration.dart';
// import 'Screens/settings.dart';
// import 'Screens/upcoming.dart';
// import 'Widgets/bottomnavigation.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp();
//
//   runApp(ProviderScope(child: const MyApp()));
// }
//
// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//           //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//           useMaterial3: true,
//           buttonTheme: const ButtonThemeData(
//             buttonColor: Color(0xFF6418C3),
//           ),
//           scaffoldBackgroundColor: CoustColors.colrButton3,
//           progressIndicatorTheme: const ProgressIndicatorThemeData(
//             color: Colors
//                 .white, // Setting CircularProgressIndicator color to white
//           ),
//           elevatedButtonTheme: ElevatedButtonThemeData(
//             style: ElevatedButton.styleFrom(
//               foregroundColor: Colors.white,
//               backgroundColor: const Color(0xFF6418C3),
//             ),
//           ),
//           bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//             selectedItemColor: CoustColors.colrButton3,
//             unselectedItemColor: CoustColors.colrSubText,
//           )),
//       // home: authState.token != null ? const HomeScreen() : const LoginScreen(),
//       routes: {
//         '/': (context) {
//           //Loginpage
//           return Consumer(
//             builder: (context, ref, child) {
//               final authState = ref.watch(authprovider);
//               if (authState.token != null) {
//                 return CoustNavigation();
//               }
//               return FutureBuilder(
//                 future: ref.watch(authprovider.notifier).tryAutoLogin(),
//                 builder: (context, snapshot) {
//                   print("print circular");
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(
//                         child:
//                             CircularProgressIndicator()); // Show SplashScreen while waiting
//                   } else {
//                     // Based on auto-login result, navigate to appropriate screen
//                     return snapshot.data == true
//                         // && authState.userStatus == true
//                         ? CoustNavigation() //Welcome page
//                         : LoginScreen(); //Login page
//                   }
//                 },
//               );
//             },
//           );
//         },
//         '/registration': (BuildContext context) {
//           //registration page
//           return const RegistrationScreen();
//         },
//         '/welcome': (BuildContext context) {
//           //welcome page
//           return CoustNavigation();
//         },
//
//         '/profile_settings': (BuildContext context) {
//           return ProfileSetingsScreen();
//         },
//         '/payment_history': (BuildContext context) {
//           return PaymenthistoryScreen();
//         },
//         '/notification_settings': (BuildContext context) {
//           return NotificationSettingsScreen();
//         },
//         '/manage_booking': (BuildContext context) {
//           return ManageBookingScreen();
//         },
//         '/upcoming_booking': (BuildContext context) {
//           return UpcomingbookingsScreen();
//         },
//         '/location': (BuildContext context) {
//           return LocationScreen();
//         },
//         // '/review': (BuildContext context) {
//         //   return ReviewScreen();
//         // },
//         // '/BookVenueScreen': (BuildContext context) {
//         //   return const `BookVenueScreen`();
//         // },
//         '/venue_details': (BuildContext context) {
//           return HallsCalendarScreen();
//           },
//           '/home': (BuildContext context) {
//             return const HomeScreen();
//           },
//           '/settings': (BuildContext context) {
//             return const SettingsScreen();
//           },
//         },
//       },
//     );
//   }
// }
