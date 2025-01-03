import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Providers/auth.dart';
import '../Providers/loaded.dart';
import '../Widgets/evaluatedbutton.dart';
import '../Widgets/heading.dart';
import '../Widgets/text.dart';
import '../Widgets/textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Function to check if a string is a valid email
  bool isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(value);
  }

  // Function to validate password
  bool isValidPassword(String value) {
    // Example: Minimum 8 characters, at least 1 letter, 1 number
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}\$');
    return passwordRegex.hasMatch(value);
  }

  final _validationkey = GlobalKey<FormState>();
  final TextEditingController _edtxtNum = TextEditingController();
  final TextEditingController _edtxtpwd = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: const Heading(
                  sText1: "Welcome!",
                  sText2: "Please login to your Account",
                  bVisibil: true,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _validationkey,
                      child: Consumer(
                        builder: (BuildContext context, WidgetRef ref,
                            Widget? child) {
                          var loader = ref.watch(
                              loadingProvider2); // to set circular progress bar
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CoustTextfield(
                                isVisible: false,
                                controller: _edtxtNum,
                                inputtype: TextInputType.emailAddress,
                                hint: "Email Address",
                                suffixIcon: const Icon(Icons.person),
                                radius: 8.0,
                                width: 10,
                                validator: (_edtxtNum) {
                                  if (_edtxtNum == null || _edtxtNum.isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  if (!isValidEmail(_edtxtNum)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              CoustTextfield(
                                controller: _edtxtpwd,
                                isVisible: false,
                                hint: "Password",
                                suffixIcon: const Icon(Icons.lock),
                                radius: 8.0,
                                width: 10,
                                validator: (_edtxtpwd) {
                                  if (_edtxtpwd == null || _edtxtpwd.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (!isValidPassword(_edtxtpwd)) {
                                    return 'Password must be at least 8 characters long and include at least one letter and one number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: CoustEvalButton(
                                  onPressed: loader == true
                                      ? null
                                      : () {
                                          if (_validationkey.currentState!
                                              .validate()) {
                                            ref.read(authprovider.notifier).loginmail(
                                                context,
                                                _edtxtNum.text.trim(),
                                                _edtxtpwd.text.trim(),
                                                ref);
                                          }
                                        },
                                  isLoading: loader,
                                  buttonName: "Login",
                                  width: double.infinity,
                                  radius: 8,
                                  FontSize: 20,
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                               Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   const coustText(
                                    sName: "Don't have an account?",
                                    Textsize: 15,
                                  ),
                                  TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/registration');
                                },
                                child: const Text(
                                  "Register here",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                                ],
                              ),
                              
                            ],
                            
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
