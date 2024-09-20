import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp_text_field/otp_field.dart';

import '../Providers/auth.dart';
import '../Providers/loaded.dart';
import '../Providers/phoneauthnotifier.dart';
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

  // Function to check if a string is a valid number
  bool isValidNumber(String value) {
    final numberRegex = RegExp(r'^\d+$');
    return numberRegex.hasMatch(value);
  }

  String sBtnName = "SendOtp"; //Button Name
  bool bOtp = false; // check for valid mobile num
  late String sOtp;

  final _validationkey = GlobalKey<FormState>();

  bool _isButtonDisabled = true;
  int _start = 30; // 30 seconds countdown
  late Timer _timer;

  void startTimer() {
    _isButtonDisabled = true;
    _start = 30;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isButtonDisabled = false;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void resendOTP() {
    // Add your OTP resend logic here
    print("OTP Resent");
    startTimer();
  }

  void _onRegistration(BuildContext context) {
    Navigator.of(context).pushNamed('/registration');
  }

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
                          sBtnName = ref.watch(
                              buttonTextProvider); // get button name from provider
                          bOtp = ref.watch(
                              VerifyOtp); // get button name from provider

                          var isPwdVisible =
                              ref.watch(enablepasswaorProvider); // Get provider

                          var loader = ref.watch(
                              loadingProvider2); // to set circularprogress bar
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CoustTextfield(
                                isVisible: false,
                                controller: _edtxtNum,
                                inputtype: TextInputType.emailAddress,
                                hint: "Phone Number/Mail Id",
                                suffixIcon: const Icon(Icons.person),
                                radius: 8.0,
                                width: 10,
                                onChanged: (edtxtNum) {
                                  if (edtxtNum == null || edtxtNum.isEmpty) {
                                    ref
                                            .read(enablepasswaorProvider.notifier)
                                            .state =
                                        false; // If num textfield is null invisble pwd field
                                  } else {
                                    if (isValidNumber(edtxtNum)) {
                                      if (edtxtNum.length >= 10) {
                                        //if valid mobile num
                                        //ref.read(enablepasswaorProvider.notifier) .state = true;
                                      }
                                      ref
                                              .read(buttonTextProvider.notifier)
                                              .state =
                                          "Send OTP"; // Set Name for button based on textfield content
                                    } else if (isValidEmail(edtxtNum)) {
                                      ref
                                          .read(enablepasswaorProvider.notifier)
                                          .state = true;
                                      ref
                                          .read(buttonTextProvider.notifier)
                                          .state = "Login";
                                    } else {
                                      ref
                                          .read(buttonTextProvider.notifier)
                                          .state = "Send OTP";
                                    }
                                  }
                                  //  if ((bOtp == true) &&(sBtnName == "Log in")){
                                  //    ref.read(buttonTextProvider.notifier).state = "Send OTP";
                                  //    ref.read(VerifyOtp.notifier).state = false;
                                  //    ref.read(enablepasswaorProvider.notifier).state = false;
                                  //   _edtxtNum.clear();
                                  // }  //otp will send only after 45 sec completed

                                  return null;
                                },
                                validator: (_edtxtNum) {
                                  if (_edtxtNum == null || _edtxtNum.isEmpty) {
                                    return 'Please enter a valid email address or number';
                                  }
                                  if (isValidNumber(_edtxtNum)) {
                                    print(
                                        "num:" + "${isValidNumber(_edtxtNum)}");
                                    if (_edtxtNum.length < 10) {
                                      return 'Enter valid Mobile Number';
                                    } else {
                                      print("elsel:${_edtxtNum.length}");
                                      return null;
                                    }
                                  } else if (!isValidEmail(_edtxtNum)) {
                                    print(
                                        "mail:" + "${isValidEmail(_edtxtNum)}");
                                    return "Pleasee enter valid emial Id";
                                  } else {
                                    print("else2:${_edtxtNum.length}");
                                    return null;
                                  }
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Column(
                                children: [
                                  isPwdVisible == true
                                      ? sBtnName == "Login"
                                          ? Container(
                                              child: CoustTextfield(
                                                controller: _edtxtpwd,
                                                isVisible: false,
                                                hint: "Password",
                                                suffixIcon:
                                                    const Icon(Icons.password),
                                                radius: 8.0,
                                                width: 10,
                                                validator: (_edtxtpwd) {
                                                  if (_edtxtpwd == null ||
                                                      _edtxtpwd.isEmpty) {
                                                    return 'Please enter password';
                                                  }
                                                },
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: OTPTextField(
                                                    onChanged: (value) {
                                                      //check_mobile_exists (Using post ) 200
                                                      print(
                                                          "Otp Value ${value}");
                                                      sOtp = value;
                                                    },
                                                    length: 6,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: _isButtonDisabled
                                                      ? null
                                                      : resendOTP,
                                                  child: Text('Resend OTP'),
                                                ),
                                              ],
                                            )
                                      : Container(),
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
                                                if ((isPwdVisible == false) &&
                                                    (sBtnName == "Send OTP")) {
                                                  // if Mobilenumber entered
                                                  ref
                                                      .read(
                                                          authprovider.notifier)
                                                      .numCheck(
                                                          context,
                                                          _edtxtNum.text.trim(),
                                                          ref);
                                                  print("print if");
                                                } else if ((bOtp == true) &&
                                                    (sBtnName == "Log in")) {
                                                  //received otp and changed the sent otp button to login
                                                  // Send Vefcation code

                                                  ref
                                                      .read(phoneAuthProvider
                                                          .notifier)
                                                      .signInWithPhoneNumber(
                                                          sOtp,
                                                          context,
                                                          ref,
                                                          _edtxtNum.text.trim(),
                                                          true);
                                                  print("print else if1");
                                                } else if ((isPwdVisible ==
                                                        true) &&
                                                    (sBtnName == "Login")) {
                                                  ref
                                                      .read(
                                                          authprovider.notifier)
                                                      .loginmail(
                                                          context,
                                                          _edtxtNum.text.trim(),
                                                          _edtxtpwd.text.trim(),
                                                          ref);
                                                  print("print else if2");
                                                } else {
                                                  print(
                                                      "visible: ${isPwdVisible}, pwd: ${sBtnName}");
                                                }
                                              }
                                            },
                                      isLoading: loader,
                                      buttonName:
                                          (ref.watch(buttonTextProvider)),
                                      width: double.infinity,
                                      radius: 8,
                                      FontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              const coustText(
                                sName: "Don't have an account?",
                                Textsize: 15,
                              ),
                              TextButton(
                                  onPressed: () {
                                    _onRegistration(context);
                                  },
                                  child: const Text(
                                    "Register here",
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontSize: 15),
                                  ))
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
