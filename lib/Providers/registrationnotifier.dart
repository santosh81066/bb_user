import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bb_user/models/registrationstatemodel.dart';  // Import your RegistrationState model
import 'package:bb_user/utils/bbapi.dart';  // Assuming you have this utility for your API endpoint

// Step 1: Define the RegistrationNotifier class
class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier() : super(RegistrationState.initial());

  // Step 2: Define the register method
  Future<void> register(
    BuildContext context,
    String? name,
    String? email,
    String? password,
    String? phoneNumber,
  ) async {
    Uri url = Uri.parse(Bbapi.registration);  // Ensure this is the correct URL for your API
    print("Registration Data: $name, $email, $password, $phoneNumber");

    try {
      final request = http.MultipartRequest('POST', url);

      // Prepare data for registration
      final data = {
        "username": name ?? '',
        "mobileno": phoneNumber ?? '',
        "email": email ?? '',
        "password": password ?? '', // Add password to the request
        "role": "v",
        "userstatus": "1",
      };

      // Add the data as a JSON string to the request
      request.fields.addAll({
        "attributes": json.encode(data),
      });

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (response.statusCode == 201) {
        // Registration successful
        state = RegistrationState.success(message: 'Registration successful');
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Registration successful'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();  // Close the dialog
                  Navigator.of(context).pushReplacementNamed('/login');  // Redirect to login screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Registration failed
        final errorMessage = json.decode(responseBody)['messages']?.join(', ') ?? "Unknown error";
        state = RegistrationState.failure(errorMessage: errorMessage);

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Registration failed: $errorMessage'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),  // Close the dialog
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Catch any errors and update the state with an error message
      print("Error during registration: $e");
      state = RegistrationState.failure(errorMessage: 'An error occurred: $e');

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('An error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),  // Close the dialog
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

// Step 3: Define the StateNotifierProvider for RegistrationNotifier
final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>(
  (ref) => RegistrationNotifier(),
);
