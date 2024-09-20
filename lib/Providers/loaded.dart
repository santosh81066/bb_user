import 'package:flutter_riverpod/flutter_riverpod.dart';

final loadingProvider = StateProvider<bool>((ref) => false);
final loadingProvider2 = StateProvider<bool>((ref) => false);   //for circular progressbar
final buttonTextProvider = StateProvider<String>((ref) => "Send OTP");  // To change Button Name in login Page
final enablepasswaorProvider = StateProvider<bool>((ref) => false);  // To set visibility of Pwd /Otp field
final VerifyOtp = StateProvider<bool>((ref) => false);  // After veryfying otp to login into app
final enableMaps = StateProvider<bool>((ref) => false);  // After veryfying otp to login into app