import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    state = state.copyWith(countdown: 45, wait: true); // Reset countdown and wait
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

  Future<void> phoneAuth(
      BuildContext context, String phoneNumber, WidgetRef ref) async {
    final loadingState = ref.watch(loadingProvider.notifier);
    final loadingState2 = ref.read(loadingProvider2.notifier);

    try {
      loadingState.state = true;

      final response = await http.post(
        Uri.parse("https://your-backend-api.com/send-otp"),
        body: {'phone_number': phoneNumber},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        state = state.copyWith(vrfCompleted: true);
        loadingState.state = false;
        loadingState2.state = false;

        _showAlertDialog(context, "Code Sent",
            "Verification code sent to your mobile number.");
      } else {
        loadingState.state = false;
        loadingState2.state = false;
        _showAlertDialog(
            context, "Error", responseData['message'] ?? "An error occurred.");
      }
    } catch (e) {
      loadingState.state = false;
      loadingState2.state = false;
      _showAlertDialog(context, "Error", e.toString());
    }
  }

  Future<void> signInWithPhoneNumber(String smsCode, BuildContext context,
      WidgetRef ref, String phoneNumber, bool login,
      {String? password, String? email, String? username}) async {
    final loadingState = ref.watch(loadingProvider.notifier);

    try {
      loadingState.state = true;

      final response = await http.post(
        Uri.parse("https://your-backend-api.com/verify-otp"),
        body: {
          'phone_number': phoneNumber,
          'otp': smsCode,
        },
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        // OTP verification successful
        if (login) {
          ref.read(authprovider.notifier).loginOtp(
              context, responseData['token'], ref); // Token from backend
        } else {
          ref.read(authprovider.notifier).registerUser(
              context, username, email, phoneNumber, password, ref);
        }
      } else {
        _showAlertDialog(context, "Error",
            responseData['message'] ?? "Invalid OTP or verification failed.");
      }

      loadingState.state = false;
    } catch (e) {
      loadingState.state = false;
      _showAlertDialog(context, "Error", e.toString());
    }
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
  }

  String cleanErrorMessage(String errorMessage) {
    String cleanedMessage = errorMessage.replaceFirst('ERROR:', '');
    cleanedMessage = cleanedMessage.replaceAll(RegExp(r'[{}]'), '');
    cleanedMessage = cleanedMessage.trim();
    return cleanedMessage;
  }
}

final phoneAuthProvider =
    StateNotifierProvider<PhoneAuthNotifier, PhoneAuthState>((ref) {
  return PhoneAuthNotifier();
});
