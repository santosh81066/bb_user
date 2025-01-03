import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/phoneauthnotifier.dart';
import '../Widgets/evaluatedbutton.dart';
import '../Widgets/heading.dart';
import '../Widgets/textfield.dart';
import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Providers/registrationnotifier.dart';
import 'package:bb_user/models/registrationstatemodel.dart';

// Step 1: Define the StateNotifierProvider
final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier();
});

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

// Controllers for input fields
final TextEditingController _edtxtMail = TextEditingController();
final TextEditingController _edtxtName = TextEditingController();
final TextEditingController _edtxtPassword = TextEditingController();
final TextEditingController _edtxtConfirmPassword = TextEditingController();
final TextEditingController _edtxtNum = TextEditingController();

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _validationKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  // Password validation function
  bool isValidPassword(String value) {
    final RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    return passwordRegex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Heading(
                  sText1: "",
                  sText2: "Register an Account",
                  bVisibil: false,
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
                          key: _validationKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CoustTextfield(
                                isVisible: false,
                                controller: _edtxtMail,
                                inputtype: TextInputType.emailAddress,
                                hint: "Mail",
                                suffixIcon: const Icon(Icons.email),
                                radius: 8.0,
                                width: double.infinity,
                                validator: (value) {
                                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an email address';
                                  } else if (!emailRegex.hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              CoustTextfield(
                                isVisible: false,
                                controller: _edtxtName,
                                inputtype: TextInputType.name,
                                hint: "Name",
                                radius: 8,
                                width: double.infinity,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              
                              // Password field: Remove the null check
                              CoustTextfield(
                                isVisible: !_isPasswordVisible,
                                controller: _edtxtPassword,
                                password: true,
                                hint: "Password",
                                radius: 8,
                                width: double.infinity,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.lock_open : Icons.lock,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  // Only check if password is valid, not empty
                                  if (!isValidPassword(value ?? "")) {
                                    return 'Password must contain at least 8 characters, a letter, and a number';
                                  }
                                  // return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              
                              // Confirm password field: Remove the null check
                              CoustTextfield(
                                isVisible: !_isPasswordVisible,
                                controller: _edtxtConfirmPassword,
                                password: true,
                                hint: "Confirm Password",
                                radius: 8,
                                width: double.infinity,
                                validator: (value) {
                                  if (value != _edtxtPassword.text.trim()) {
                                    return 'Passwords do not match';
                                  }
                                  // return null;
                                },
                              ),
                              
                              const SizedBox(height: 10),
                              
                              CoustTextfield(
                                isVisible: false,
                                controller: _edtxtNum,
                                inputtype: TextInputType.phone,
                                hint: "Phone Number",
                                radius: 8,
                                width: double.infinity,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a phone number';
                                  } else if (value.length != 10) {
                                    return 'Please enter a valid 10-digit phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Step 2: Using Consumer widget to access the state and interact with RegistrationNotifier
                              Consumer(
                                builder: (context, ref, child) {
                                  final registrationState = ref.watch(registrationProvider);

                                  return CoustEvalButton(
                                    buttonName: "Register",
                                    width: double.infinity,
                                    bgColor: CoustColors.colrButton3,
                                    radius: 8,
                                    FontSize: 20,
                                    onPressed: () async {
                                      if (_validationKey.currentState!.validate()) {
                                        // Step 3: Trigger the registration logic
                                        ref.read(registrationProvider.notifier).register(
                                          context,
                                          _edtxtName.text.trim(),
                                          _edtxtMail.text.trim(),
                                          _edtxtPassword.text.trim(),
                                          _edtxtNum.text.trim(),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
