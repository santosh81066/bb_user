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

  Future<void> loginmail(BuildContext context, String? username,
      String? password, WidgetRef ref) async {
    const url = Bbapi.login_mail;
    final prefs = await SharedPreferences.getInstance();
    final loadingState = ref.read(loadingProvider2.notifier);
    loadingState.state = true;

    var response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type':
          'application/json', // Set the content type to application/json
        },
        body: json.encode({
          "email": username!,
          "password": password!,
        }));

    var userDetails = json.decode(response.body);
    switch (response.statusCode) {
      case 200:
        loadingState.state = false;
        // Extract data from the 'data' key in the response
        final userDataFromServer = userDetails['data'];
        state = state.copyWith(
          userId: userDataFromServer["user_id"] as int?, // Cast to int
          token: userDataFromServer["access_token"] as String?,
          username: userDataFromServer["username"] as String?,
          email: userDataFromServer["email"] as String?,
          mobileno: userDataFromServer["mobile_no"].toString(), // Force String
          usertype: userDataFromServer["user_role"] as String?,
          profilePic: userDataFromServer["profile_pic"] as String?, // Added profile_pic
        );

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

        print("Email login successful - profilePic: ${state.profilePic}");
        Navigator.of(context).pushNamed('/welcome');
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