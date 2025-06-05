import 'package:bb_user/Providers/firebase_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Colors/coustcolors.dart';
import 'L10n/app_localizations.dart';
import 'Providers/auth.dart';
import 'Providers/theme_provider.dart';
import 'Providers/language_provider.dart';
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
import 'Screens/venues.dart';
import 'Screens/walletscreen.dart';
import 'Widgets/bottomnavigation.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure edge-to-edge display for Android 15+
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notification service with proper error handling
    bool notificationInitialized = await EnhancedFirebaseNotificationService.initialize();
    if (notificationInitialized) {
    } else {
    }

    // Try to sign in anonymously on app start
    final FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    } else {
    }
  } catch (e) {
    // Don't throw here - let the app continue even if Firebase fails
  }
}



void main() async {
  await initializeFirebase();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6418C3),
      brightness: Brightness.light,
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF6418C3),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF6418C3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF6418C3),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF6418C3),
      unselectedItemColor: CoustColors.colrSubText,
      backgroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF6418C3),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6418C3),
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6418C3),
      brightness: Brightness.dark,
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF6418C3),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF6418C3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF6418C3),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF6418C3),
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFF1E1E1E), // Removed const here as well
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF6418C3),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6418C3),
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData( // Changed from CardTheme to CardThemeData
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider.select((theme) =>
    ref.read(themeProvider.notifier).themeMode));
    ref.watch(languageProvider);

    return MaterialApp(
      title: 'BANQUETBOOKZ-U',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

      locale: ref.read(languageProvider.notifier).locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('te', ''),
        Locale('hi', ''),
      ],

      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,

      // Add this builder to handle safe area insets properly
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).brightness == Brightness.light
              ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          )
              : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: child!,
        );
      },

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
          return const StepByStepHallBookingScreen();
        },
        '/properties': (BuildContext context) {
          return const Venuscreen();
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
      onUnknownRoute: (settings) {
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
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Color(0xFF6418C3),
      body: SafeArea(
        child: Center(
          child: FutureBuilder(
            future: _authCheckFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
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
                      localizations?.loading ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              } else {
                return snapshot.data == true
                    ? ResponsiveNavigation()
                    : const ResponsiveLoginScreen();
              }
            },
          ),
        ),
      ),
    );
  }
}