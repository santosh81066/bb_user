// ignore_for_file: unused_import

import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Screens/review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Providers/auth.dart';
import '../Providers/loaded.dart';
import '../Widgets/text.dart';
import '../utils/bbapi.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;

  Future<void> logout(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('SharedPreferences cleared');
    ref.read(authprovider.notifier).clear();
    ref.read(enablepasswaorProvider.notifier).state = false;
    if (!prefs.containsKey('userData')) {
      print('trylogin is false');
      // Navigator.pushNamed(context, '/');
    }
  }

  Future<void> deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      setState(() {
        _isDeleting = true;
      });

      // Get user ID from auth provider
      final authState = ref.read(authprovider);
      final userId = authState.userId;

      if (userId == null) {
        throw Exception("User ID not found");
      }

      // Make API call to delete account
      final response = await http.delete(
        Uri.parse(Bbapi.login_mail),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "id": userId,
        }),
      );

      if (response.statusCode == 200) {
        // Account deleted successfully, now log out
        await logout(context, ref);

        // Navigate to login or landing page
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Warning: This action will permanently delete your account and all associated data. This action cannot be undone. Are you sure you want to proceed?',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: _isDeleting
                ? null
                : () {
                    Navigator.of(ctx).pop();
                    deleteAccount(context, ref);
                  },
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void profile_settings() {
    Navigator.pushNamed(context, '/profile_settings');
  }

  void payment_history() {
    Navigator.pushNamed(context, '/payment_history');
  }

  void notification_settings() {
    Navigator.pushNamed(context, '/notification_settings');
  }

  void Walllet() {
    Navigator.pushNamed(context, '/wallet');
  }

  void review() {
    Navigator.pushNamed(context, '/review');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 130,
                      // ignore: unnecessary_const
                      decoration: const BoxDecoration(
                          color: Color(0xFF6418C3),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadiusDirectional.only(
                              bottomEnd: Radius.circular(25),
                              bottomStart: Radius.circular(25))),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 30.0, left: 15),
                        child: Text("Settings",
                            style: TextStyle(
                                color: CoustColors.colrEdtxt4, fontSize: 20)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0, left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton(
                              onPressed: () {
                                profile_settings();
                              },
                              child: const Text(
                                "Profile Settings",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                          const SizedBox(
                            height: 20,
                          ),
                          TextButton(
                              onPressed: () {
                                payment_history();
                              },
                              child: const Text(
                                "Payment History",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                          const SizedBox(
                            height: 20,
                          ),
                          TextButton(
                              onPressed: () {
                                notification_settings();
                              },
                              child: const Text(
                                "Notification Settings",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                          const SizedBox(
                            height: 20,
                          ),
                          TextButton(
                              onPressed: () {
                                Walllet();
                              },
                              child: const Text(
                                "Walllet",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                          const SizedBox(
                            height: 20,
                          ),

                          TextButton(
                              onPressed: () {
                                logout(context, ref);
                              },
                              child: const Text(
                                "Logout",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              )),
                          const SizedBox(
                            height: 20,
                          ),
                          TextButton(
                              onPressed: () {
                                review();
                              },
                              child: const Text(
                                "Leave Review",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: CoustColors.colrEdtxt2,
                                    decoration: TextDecoration.underline),
                              )),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 20.0),
                child: TextButton(
                    onPressed: () {
                      _showDeleteConfirmationDialog(context, ref);
                    },
                    child: const Text(
                      "Delete Account",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CoustColors.colrEdtxt3,
                          decoration: TextDecoration.underline),
                    )),
              )
            ],
          );
        },
      ),
    );
  }
}
