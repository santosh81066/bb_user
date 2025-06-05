// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/authstate.dart';
import '../utils/bbapi.dart';
import 'loaded.dart';
import 'phoneauthnotifier.dart';
import 'package:http_parser/http_parser.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('userData')) {
      return false;
    }

    final userDataString = prefs.getString('userData');
    if (userDataString == null || userDataString.isEmpty) {
      return false;
    }

    try {
      final extractData = json.decode(userDataString) as Map<String, dynamic>;
      // Debugging print
      print("Auto login data: $extractData");

      // Update the state with the retrieved data including profile_pic
      state = AuthState.fromJson(extractData);

      // Verify state was updated
      print("Auto login successful - profilePic: ${state.profilePic}");

      return true;
    } catch (e) {
      print("Auto login error: $e");
      return false;
    }
  }

  Future<void> registerUser(BuildContext context, String? username,
      String? email, String? phonenum, String? password, WidgetRef ref) async {
    const url = Bbapi.register;

    final prefs = await SharedPreferences.getInstance();
    final loadingState = ref.read(loadingProvider2.notifier);
    loadingState.state = true;
    var response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type':
          'application/json', // Set the content type to application/json
        },
        body: json.encode({
          "username": username!,
          "email": email!,
          "mobile_no": phonenum!,
          "password": password!
        }));
    var userDetails = json.decode(response.body);
    switch (response.statusCode) {
      case 201:
        loadingState.state = false;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Registation successful'),
              actions: [
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        Navigator.of(context)
            .pushNamed('/'); //Goto Login page if Registered succesfully
        break;
      case 400:
        loadingState.state = false;
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Failed'),
                content: Text("$userDetails"),
                actions: [
                  ElevatedButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
        break;
    }
    // Handle other status codes as needed
  }

  Future<void> numCheck(
      BuildContext context, String? phonenum, WidgetRef ref) async {
    const url = Bbapi.mobilecheck;
    final prefs = await SharedPreferences.getInstance();
    final loadingState = ref.read(loadingProvider2.notifier);
    loadingState.state = true;
    var response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type':
          'application/json', // Set the content type to application/json
        },
        body: json.encode({"mobile_no": phonenum}));
    var userDetails = json.decode(response.body);
    switch (response.statusCode) {
      case 200:
      // loadingState.state = false;
        ref.read(enablepasswaorProvider.notifier).state = true;
        ref
            .read(phoneAuthProvider.notifier)
            .phoneAuth(context, "$phonenum", ref);

        break;
      case 400:
        loadingState.state = false;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(cleanErrorMessage(userDetails)),
              actions: [
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        break;

      case 500:
        loadingState.state = false;
        break;
    }
    // Handle other status codes as needed
  }

  Future<void> loginOtp(
      BuildContext context, String? token, WidgetRef ref) async {
    const url = Bbapi.login_otp;
    //print("Otp check${otp}");
    final prefs = await SharedPreferences.getInstance();
    String? verificationId = prefs.getString('verificationid');
    final loadingState = ref.read(loadingProvider2.notifier);
    loadingState.state = true;

    var response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type':
          'application/json', // Set the content type to application/json
        },
        body: json.encode({"access_token": token}));
    var userDetails = json.decode(response.body);
    switch (response.statusCode) {
      case 200:
        loadingState.state = false;
        // Extract data from the 'data' key
        final userDataFromServer = userDetails['data'];
        state = state.copyWith(
            userId: userDataFromServer["user_id"], // From 'data'
            token: userDataFromServer["access_token"],
            username: userDataFromServer["username"],
            email: userDataFromServer["email"],
            mobileno: userDataFromServer["mobile_no"]?.toString(),
            usertype: userDataFromServer["user_role"],
            profilePic: userDataFromServer["profile_pic"]); // Added profile_pic

        final userData = json.encode({
          'user_id': state.userId,
          'access_token': state.token,
          'username': state.username,
          'email': state.email,
          'mobile_no': state.mobileno,
          'user_role': state.usertype,
          'profile_pic': state.profilePic, // Added profile_pic to storage
        });
        await prefs.setString('userData', userData);

        print("OTP Login successful - profilePic: ${state.profilePic}");
        break;
      case 400:
        loadingState.state = false;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(cleanErrorMessage(userDetails)),
              //content: Text("$userDetails"),
              actions: [
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        break;
      case 500:
        loadingState.state = false;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(cleanErrorMessage(userDetails)),
              //content: Text("$userDetails"),
              actions: [
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        break;
    }
    // Handle other status codes as needed
  }

  Future<void> updateUserProfile(
      BuildContext context,
      String? username,
      String? phonenum,
      String? email,
      String? password,
      File? profilePic,
      WidgetRef ref) async {
    const url = Bbapi.update_user;
    final prefs = await SharedPreferences.getInstance();
    final extractData =
    json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    String token = extractData['access_token'];
    String usertype = extractData['user_role'];
    int userId = extractData['user_id'];

    final loadingState = ref.read(loadingProvider2.notifier);
    loadingState.state = true;

    // Create multipart request for profile picture upload
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers
    request.headers.addAll({
      'Authorization': 'Token $token',
    });

    // Add text fields
    request.fields['id'] = userId.toString();
    request.fields['username'] = username!;
    request.fields['email'] = email!;
    request.fields['mobile_no'] = phonenum!;

    // Add password if provided
    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }

    // Add profile picture if provided
    if (profilePic != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_pic',
        profilePic.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Debug response
      print("Profile update response status: ${response.statusCode}");
      print("Profile update response body: ${response.body}");

      var userDetails = json.decode(response.body);

      switch (response.statusCode) {
        case 200:
          loadingState.state = false;

          // Make sure we're extracting the correct data format from the response
          var updatedUsername = userDetails["username"] ?? username;
          var updatedEmail = userDetails["email"] ?? email;
          var updatedMobileNo = userDetails["mobile_no"]?.toString() ?? phonenum;
          var updatedProfilePic = userDetails["profile_pic"];

          // Debug profile pic data
          print("Updated profile pic URL: $updatedProfilePic");

          // Update local state with new data
          state = state.copyWith(
              userId: userId,
              token: token,
              username: updatedUsername,
              email: updatedEmail,
              mobileno: updatedMobileNo,
              profilePic: updatedProfilePic,
              usertype: usertype);

          // Save updated data to SharedPreferences
          final userData = json.encode({
            'user_id': state.userId,
            'access_token': state.token,
            'username': state.username,
            'email': state.email,
            'mobile_no': state.mobileno,
            'profile_pic': state.profilePic,
            'user_role': state.usertype,
          });

          await prefs.setString('userData', userData);

          // Verify the data was saved correctly
          final verifyData =
          json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
          print("Verified saved userData: $verifyData");

          // Show success message
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Success'),
                content: const Text('Profile updated successfully'),
                actions: [
                  ElevatedButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          break;

        case 400:
          loadingState.state = false;
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Failed'),
                  content: Text(cleanErrorMessage(userDetails.toString())),
                  actions: [
                    ElevatedButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
          break;

        default:
          loadingState.state = false;
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text(
                      'An unexpected error occurred: ${response.statusCode}'),
                  actions: [
                    ElevatedButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
          break;
      }
    } catch (e) {
      loadingState.state = false;
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Network error: $e'),
              actions: [
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    }
  }

  // Add this method to AuthNotifier class
  Future<void> refreshUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userData')) {
      final extractData =
      json.decode(prefs.getString('userData')!) as Map<String, dynamic>;

      print("Refreshing user data: $extractData");

      // Force state update with refreshed data
      state = AuthState.fromJson(extractData);

      // Debug the state after updating
      print("State after refresh - profilePic: ${state.profilePic}");

      // Emit notification that state has changed
      state = state.copyWith(); // This forces listeners to update
    }
  }

  void clear() {
    state = state.clear(); // Reset to initial state
    state = state.copyWith();
  }

// DEBUGGED VERSION OF loginmail METHOD

  Future<void> loginmail(BuildContext context, String? username,
      String? password, WidgetRef ref) async {
    const url = Bbapi.login_mail;
    final prefs = await SharedPreferences.getInstance();
    final loadingState = ref.read(loadingProvider2.notifier);

    // Add input validation
    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      _showErrorDialog(context, 'Invalid Input', 'Please enter both email and password');
      return;
    }

    loadingState.state = true;

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "email": username,
          "password": password,
        }),
      );

      // Debug: Print response for troubleshooting
      print("Login response status: ${response.statusCode}");
      print("Login response body: ${response.body}");

      // Check if response body is empty
      if (response.body.isEmpty) {
        loadingState.state = false;
        _showErrorDialog(context, 'Server Error', 'Empty response from server');
        return;
      }

      // Parse response with error handling
      Map<String, dynamic> userDetails;
      try {
        userDetails = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        loadingState.state = false;
        print("JSON decode error: $e");
        _showErrorDialog(context, 'Parse Error', 'Invalid response format from server');
        return;
      }

      switch (response.statusCode) {
        case 200:
          loadingState.state = false;

          // Validate response structure
          if (userDetails['data'] == null) {
            _showErrorDialog(context, 'Invalid Response', 'Missing user data in server response');
            return;
          }

          final userDataFromServer = userDetails['data'] as Map<String, dynamic>;

          // Validate required fields exist
          if (userDataFromServer["user_id"] == null ||
              userDataFromServer["access_token"] == null) {
            _showErrorDialog(context, 'Invalid Response', 'Missing required user information');
            return;
          }

          // Update state with null safety
          state = state.copyWith(
            userId: userDataFromServer["user_id"] as int?,
            token: userDataFromServer["access_token"] as String?,
            username: userDataFromServer["username"] as String?,
            email: userDataFromServer["email"] as String?,
            mobileno: userDataFromServer["mobile_no"]?.toString() ?? '',
            usertype: userDataFromServer["user_role"] as String?,
            profilePic: userDataFromServer["profile_pic"] as String?,
          );

          // Save user data with error handling
          try {
            final userData = json.encode({
              'user_id': state.userId,
              'access_token': state.token,
              'username': state.username,
              'email': state.email,
              'mobile_no': state.mobileno,
              'user_role': state.usertype,
              'profile_pic': state.profilePic,
            });
            await prefs.setString('userData', userData);

            print("Email login successful - profilePic: ${state.profilePic}");

            // Check if context is still valid before navigation
            if (context.mounted) {
              Navigator.of(context).pushNamed('/welcome');
            }
          } catch (e) {
            print("Error saving user data: $e");
            _showErrorDialog(context, 'Storage Error', 'Failed to save login data');
          }
          break;

        case 400:
          loadingState.state = false;
          _showErrorDialog(context, 'Login Failed', userDetails);
          break;


// FIXED 401 ERROR CASE - USER FRIENDLY VERSION

        case 401:
          loadingState.state = false;
          _showErrorDialog(
              context,
              'Login Failed',
              'The email or password you entered is incorrect. Please check your credentials and try again.'
          );
          break;


        case 403:
          loadingState.state = false;
          _showErrorDialog(context, 'Access Denied', 'Account may be suspended or deactivated');
          break;

        case 500:
          loadingState.state = false;
          _showErrorDialog(context, 'Server Error', 'Internal server error. Please try again later.');
          break;

        case 504:
          loadingState.state = false;
          _showErrorDialog(context, 'Service Unavailable', 'Server is temporarily unavailable. Please try again later.');
          break;

        default:
          loadingState.state = false;
          _showErrorDialog(context, 'Unexpected Error', 'An unexpected error occurred (${response.statusCode})');
          break;
      }

    } catch (e) {
      // Handle network errors, timeouts, etc.
      loadingState.state = false;
      print("Network error in loginmail: $e");

      String errorMessage;
      if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      } else {
        errorMessage = 'Network error occurred. Please try again.';
      }

      _showErrorDialog(context, 'Connection Error', errorMessage);
    }
  }

// HELPER METHODS (Add these to your AuthNotifier class)

// Reusable error dialog method
  void _showErrorDialog(BuildContext context, String title, dynamic errorData) {
    String errorMessage = _extractErrorMessage(errorData);

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

// Extract error message from different response formats
  String _extractErrorMessage(dynamic errorData) {
    if (errorData == null) return "Unknown error occurred";

    if (errorData is String) {
      return cleanErrorMessage(errorData);
    }

    if (errorData is Map<String, dynamic>) {
      // Check for common error message keys
      if (errorData.containsKey('message')) {
        return cleanErrorMessage(errorData['message'].toString());
      } else if (errorData.containsKey('error')) {
        return cleanErrorMessage(errorData['error'].toString());
      } else if (errorData.containsKey('detail')) {
        return cleanErrorMessage(errorData['detail'].toString());
      } else if (errorData.containsKey('non_field_errors')) {
        // Django REST framework format
        var errors = errorData['non_field_errors'];
        if (errors is List && errors.isNotEmpty) {
          return cleanErrorMessage(errors.first.toString());
        }
      } else {
        // If no specific error key, clean the entire response
        return cleanErrorMessage(errorData.toString());
      }
    }

    return cleanErrorMessage(errorData.toString());
  }

// IMPROVED cleanErrorMessage function
  String cleanErrorMessage(String errorMessage) {
    if (errorMessage.isEmpty) return "Unknown error";

    String cleanedMessage = errorMessage;

    // Remove common prefixes
    cleanedMessage = cleanedMessage.replaceAll(RegExp(r'^(ERROR|Error|FAILED|Failed):\s*', caseSensitive: false), '');

    // Remove JSON brackets and quotes
    cleanedMessage = cleanedMessage.replaceAll(RegExp(r'[{}""\[\]]'), '');

    // Clean up key-value pairs (e.g., "key: value" -> "value")
    cleanedMessage = cleanedMessage.replaceAll(RegExp(r'\w+:\s*'), '');

    // Remove extra whitespace and newlines
    cleanedMessage = cleanedMessage.replaceAll(RegExp(r'\s+'), ' ');
    cleanedMessage = cleanedMessage.trim();

    // Capitalize first letter
    if (cleanedMessage.isNotEmpty) {
      cleanedMessage = cleanedMessage[0].toUpperCase() + cleanedMessage.substring(1);
    }

    // If still empty after cleaning, provide default message
    if (cleanedMessage.isEmpty) {
      return "An error occurred while processing your request";
    }

    return cleanedMessage;
  }

  // New method to fetch user list (based on your Postman response)
  Future<List<Map<String, dynamic>>?> fetchUserList() async {
    const url = 'http://www.gocodedesigners.com/bbadminlogin';

    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      print("Error fetching user list: $e");
      return null;
    }
  }

  // Helper method to get full profile picture URL
  String? getFullProfilePicUrl(String? profilePic) {
    if (profilePic == null || profilePic.isEmpty) {
      return null;
    }

    // If it's already a full URL, return as is
    if (profilePic.startsWith('http')) {
      return profilePic;
    }

    // Construct full URL - adjust base URL as needed
    return 'http://www.gocodedesigners.com/$profilePic';
  }
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

final authprovider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});