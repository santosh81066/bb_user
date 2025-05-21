import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Colors/coustcolors.dart';
import 'Providers/auth.dart';
import 'Screens/hallscalendar.dart';
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

Future<void> initializeFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Try to sign in anonymously on app start
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print('Anonymous auth successful on app start');
    } else {
      print('Already authenticated: ${auth.currentUser!.uid}');
    }
  } catch (e) {
    print('Error during initial authentication: $e');
  }
}

void main() async {
  await initializeFirebase();

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BANQUETBOOKZ!',
      theme: ThemeData(
          //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          buttonTheme: const ButtonThemeData(
            buttonColor: Color(0xFF6418C3),
          ),
          scaffoldBackgroundColor: CoustColors.colrButton3,
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors
                .white, // Setting CircularProgressIndicator color to white
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
          )),
      routes: {
        '/': (context) {
          //Loginpage
          return Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authprovider);

              // If already authenticated, go directly to navigation
              if (authState.token != null) {
                return ResponsiveNavigation();
              }

              // Use a StatefulBuilder to prevent rebuilds from triggering re-login attempts
              return _AuthCheckScreen();
            },
          );
        },
        '/registration': (BuildContext context) {
          //registration page
          return const RegistrationScreen();
        },
        '/welcome': (BuildContext context) {
          //welcome page
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
    );
  }
}

// Separate widget to handle authentication check only once
class _AuthCheckScreen extends ConsumerStatefulWidget {
  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<_AuthCheckScreen> {
  late Future<bool> _authCheckFuture;

  @override
  void initState() {
    super.initState();

    // Run tryAutoLogin exactly once when this widget initializes
    _authCheckFuture = ref.read(authprovider.notifier).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          // Based on auto-login result, navigate to appropriate screen
          return snapshot.data == true
              ? ResponsiveNavigation()
              : const LoginScreen();
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
