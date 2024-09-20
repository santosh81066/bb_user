import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/phoneauthstate.dart';
import 'auth.dart';
import 'loaded.dart';

class PhoneAuthNotifier extends StateNotifier<PhoneAuthState> {
  PhoneAuthNotifier() : super(PhoneAuthState());
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void restartTimer() {
    state =
        state.copyWith(countdown: 45, wait: true); // Reset countdown and wait
    startTimer(); // Start the timer again
  }

  void startTimer() {
    _timer?.cancel(); // Cancel any existing timer

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdown == 0) {
        waitTime();
        timer.cancel();
      } else {
        updateCountdown();
      }
    });
  }

  void updateCountdown() {
    state = state.copyWith(countdown: state.countdown - 1);
  }

  void waitTime() {
    state = state.copyWith(wait: !state.wait);
  }

  void updateOtp(String otp) {
    state = state.copyWith(otp: otp);
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  Future<void> phoneAuth(
      BuildContext context, String phoneNumber, WidgetRef ref) async {
    final loadingState = ref.watch(loadingProvider.notifier);
    final loadingState2 = ref.read(loadingProvider2.notifier);
    final FirebaseAuth auth =
        FirebaseAuth.instance; // Ensure you have an instance of FirebaseAuth

    try {
      loadingState.state = true;
      print("phonenum:$phoneNumber");
      await auth.verifyPhoneNumber(
        phoneNumber: "+91$phoneNumber",
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) async {
          loadingState.state = false;

          // Handle auto-retrieval or instant verification
        },
        verificationFailed: (FirebaseException exception) {
          loadingState.state = false;
          loadingState2.state = false;
          _showAlertDialog(context, "Verification Failed",
              exception.message ?? "An error occurred.");
        },
        codeSent: (String verificationId, [int? forceResendingToken]) async {
          state = state.copyWith(vrfCompleted: true);
          loadingState.state = false;
          loadingState2.state = false;
          ref.read(buttonTextProvider.notifier).state = "Log in";
          ref.read(VerifyOtp.notifier).state = true;
          //ref.read(enablepasswaorProvider.notifier).state = false;
          print("Vrification Done ${state.vrfCompleted}");
          print("VerID1 $verificationId");
          _showAlertDialog(
              context, "Code Sent", "Verification code sent on your mobile.");
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('verificationid', verificationId);
        },
        timeout: const Duration(seconds: 30),
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle auto retrieval timeout
        },
      );
    } catch (e) {
      loadingState2.state = false;
      loadingState.state = false;
      _showAlertDialog(context, "Error", e.toString());
    }
  }

  Future<void> signInWithPhoneNumber(String smsCode, BuildContext context,
      WidgetRef ref, String phoneNumber, bool login,
      {String? password, String? email, String? username}) async {
    print("Sms${smsCode}");
    final prefs = await SharedPreferences.getInstance();
    String? verificationId = prefs.getString('verificationid');
    Set<String> keys = prefs.getKeys();

    // Print keys
    print('SharedPreferences Keys: $keys');

    if (verificationId == null) {
      _showAlertDialog(context, "Error", "Verification ID is null.");
      return;
    }
    final loadingState = ref.watch(loadingProvider.notifier);
    try {
      loadingState.state = true;
      print("VerID${prefs.getString('verificationid')}");
      print("Sms${smsCode}");
      AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);

      await auth.signInWithCredential(credential).then((value) async {
        if (value.user != null) {
          var user = auth.currentUser!;
          print("vreification success");

          String? firebaseToken = await user.getIdToken();
          print(user.getIdToken());
          if (login) {
            ref
                .read(authprovider.notifier)
                .loginOtp(context, firebaseToken, ref);
          } else {
            ref.read(authprovider.notifier).registerUser(
                context, username, email, phoneNumber, password, ref);
          }
        } else {
          print("vreification failed");
        }
      });

      loadingState.state = false;
    } catch (e) {
      print("Catchs123R${e}");
      loadingState.state = false;
      if (e is PlatformException) {
        PlatformException exception = e;
        if (exception.code == 'firebase_auth') {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text(exception.message!),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                );
              });
        }

        //showsnackbar(context, e.toString());
      }
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('${e}'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    }
    loadingState.state = false;
  }

  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(cleanErrorMessage(message)),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    // Implement any additional logic as needed
  }

  String cleanErrorMessage(String errorMessage) {
    // Remove the "ERROR:" prefix
    String cleanedMessage = errorMessage.replaceFirst('ERROR:', '');

    // Remove the curly brackets
    cleanedMessage = cleanedMessage.replaceAll(RegExp(r'[{}]'), '');

    // Trim any extra whitespace
    cleanedMessage = cleanedMessage.trim();

    return cleanedMessage;
  }
}

final phoneAuthProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>((ref) {
  return PhoneAuthNotifier();
});
