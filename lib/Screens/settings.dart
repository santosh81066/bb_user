import 'package:bb_user/Colors/coustcolors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Providers/auth.dart';
import '../Providers/loaded.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  void profile_settings() {
    Navigator.pushNamed(context, '/profile_settings');
  }

  void payment_history() {
    Navigator.pushNamed(context, '/payment_history');
  }

  void notification_settings() {
    Navigator.pushNamed(context, '/notification_settings');
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
                padding: const EdgeInsets.only(top: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 90,
                      // ignore: unnecessary_const
                      decoration: const BoxDecoration(
                          color: Color(0xFF6418C3),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadiusDirectional.only(
                              bottomEnd: Radius.circular(25),
                              bottomStart: Radius.circular(25))),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 20.0, left: 15),
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
                              onPressed: () {},
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
                              onPressed: () {},
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
                padding: const EdgeInsets.only(left: 10.0),
                child: TextButton(
                    onPressed: () {},
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
