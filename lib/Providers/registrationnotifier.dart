import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bb_user/models/registrationstatemodel.dart';
import 'package:bb_user/utils/bbapi.dart';

import '../Screens/login.dart';

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier() : super(RegistrationState.initial());

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void setProfileImage(File image) {
    state = state.copyWith(profileImage: image);
  }

  // Updated register method with Firebase email verification
  Future<void> register(
      BuildContext context,
      String? name,
      String? email,
      String? password,
      String? phoneNumber,
      File? profileImage,
      ) async {
    if (email == null || password == null || name == null) {
      _showErrorDialog(context, 'Please fill all required fields');
      return;
    }

    // Set loading state
    state = RegistrationState.loading();

    try {
      // Step 1: Create user with Firebase Auth
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Step 2: Update user profile with display name
        await user.updateDisplayName(name);

        // Step 3: Send email verification
        await user.sendEmailVerification();

        // Step 4: Show verification dialog and wait for verification
        bool isVerified = await _showEmailVerificationDialog(context, user);

        if (isVerified) {
          // Step 5: Register with your custom API after email verification
          await _registerWithCustomAPI(context, name, email, password, phoneNumber, profileImage, user.uid);
        } else {
          // Delete Firebase user if email not verified
          await user.delete();
          state = RegistrationState.failure(errorMessage: 'Email verification failed');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      state = RegistrationState.failure(errorMessage: errorMessage);
      _showErrorDialog(context, errorMessage);
    } catch (e) {
      print("Error during registration: $e");
      state = RegistrationState.failure(errorMessage: 'An error occurred: $e');
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

  // Show email verification dialog
  Future<bool> _showEmailVerificationDialog(BuildContext context, User user) async {
    bool isVerified = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Email Icon
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 40,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),

              const SizedBox(height: 16),

              // Email address with highlight
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  user.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                'We\'ve sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Resend Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await user.sendEmailVerification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Verification email sent!'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.error, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Failed to resend email'),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resend'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.blue.shade300),
                        foregroundColor: Colors.blue.shade600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Verify Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show loading state
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          await user.reload();
                          User? refreshedUser = FirebaseAuth.instance.currentUser;

                          // Close loading dialog
                          Navigator.of(context).pop();

                          if (refreshedUser != null && refreshedUser.emailVerified) {
                            Navigator.of(context).pop();
                            isVerified = true;

                            // Success feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.verified, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Email verified successfully!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Please verify your email first'),
                                  ],
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          // Close loading dialog
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.error, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Verification failed. Try again.'),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.verified_user),
                      label: const Text('I\'ve Verified'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cancel Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  isVerified = false;
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Help text
              Text(
                'Didn\'t receive the email? Check your spam folder or try resending.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return isVerified;
  }

  // Register with your custom API after Firebase verification
  Future<void> _registerWithCustomAPI(
      BuildContext context,
      String name,
      String email,
      String password,
      String? phoneNumber,
      File? profileImage,
      String firebaseUid,
      ) async {
    Uri url = Uri.parse(Bbapi.registration);
    print("Registration Data: $name, $email, $phoneNumber, Firebase UID: $firebaseUid");

    try {
      final request = http.MultipartRequest('POST', url);

      if (profileImage != null) {
        print("Uploading profile image: ${profileImage.path}");
        request.files.add(
          await http.MultipartFile.fromPath(
            'profilepic',
            profileImage.path,
          ),
        );
      } else {
        print("No profile image selected");
      }

      // Prepare data for registration including Firebase UID
      final data = {
        "username": name,
        "mobileno": phoneNumber ?? '',
        "email": email,
        "password": password,
        "role": "u",
        "userstatus": "1",
        "firebase_uid": firebaseUid, // Add Firebase UID to your API
        "email_verified": true, // Mark as verified since Firebase verification is complete
      };

      request.fields.addAll({
        "attributes": json.encode(data),
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (response.statusCode == 201) {
        state = RegistrationState.success(message: 'Registration successful');

        _showSuccessDialog(context, 'Registration completed successfully! You can now sign in.');
      } else {
        final errorMessage = json.decode(responseBody)['messages']?.join(', ') ?? "Unknown error";
        state = RegistrationState.failure(errorMessage: errorMessage);
        _showErrorDialog(context, 'Registration failed: $errorMessage');

        // Delete Firebase user if API registration fails
        User? user = _firebaseAuth.currentUser;
        if (user != null) {
          await user.delete();
        }
      }
    } catch (e) {
      print("Error during API registration: $e");
      state = RegistrationState.failure(errorMessage: 'An error occurred: $e');
      _showErrorDialog(context, 'An error occurred: $e');

      // Delete Firebase user if API registration fails
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        try {
          await user.delete();
        } catch (deleteError) {
          print("Error deleting Firebase user: $deleteError");
        }
      }
    }
  }

  // Get user-friendly Firebase error messages
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred: $errorCode';
    }
  }

  // Show success dialog
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(context,MaterialPageRoute(builder:(context)=>const ResponsiveLoginScreen()));
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// StateNotifierProvider for RegistrationNotifier
final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>(
      (ref) => RegistrationNotifier(),
);