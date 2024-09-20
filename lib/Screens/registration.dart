import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp_text_field/otp_field.dart';

import '../Providers/loaded.dart';
import '../Providers/phoneauthnotifier.dart';
import '../Widgets/evaluatedbutton.dart';
import '../Widgets/heading.dart';
import '../Widgets/textfield.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

TextEditingController _edtxtMail = TextEditingController();
TextEditingController _edtxtName = TextEditingController();
TextEditingController _edtxtpassword = TextEditingController();
TextEditingController _edtxtNum = TextEditingController();

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _validationkey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                child: Heading(
                  sText1: "",
                  sText2: "Register an Account",
                  bVisibil: false,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _validationkey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CoustTextfield(
                            isVisible: false,
                            controller: _edtxtMail,
                            inputtype: TextInputType.emailAddress,
                            hint: "Mail",
                            suffixIcon: const Icon(Icons.person),
                            radius: 8.0,
                            width: 10,
                            validator: (_edtxtMail) {
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (_edtxtMail == null || _edtxtMail.isEmpty) {
                                return 'Please enter an email address';
                              } else if (!emailRegex.hasMatch(_edtxtMail)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          CoustTextfield(
                            isVisible: false,
                            controller: _edtxtName,
                            inputtype: TextInputType.name,
                            hint: "Name",
                            radius: 8,
                            width: 10,
                            validator: (_edtxtName) {
                              if (_edtxtName == null || _edtxtName.isEmpty) {
                                return 'Please enter an Name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          CoustTextfield(
                            isVisible: false,
                            controller: _edtxtpassword,
                            password: true,
                            hint: "Password",
                            radius: 8,
                            width: 10,
                            validator: (_edtxtpassword) {
                              if (_edtxtpassword == null ||
                                  _edtxtpassword.isEmpty) {
                                return 'Please enter an password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: CoustTextfield(
                                  isVisible: false,
                                  controller: _edtxtNum,
                                  inputtype: TextInputType.phone,
                                  hint: "Phone Number",
                                  radius: 8,
                                  width: 10,
                                  validator: (_edtxtNum) {
                                    if (_edtxtNum == null ||
                                        _edtxtNum.isEmpty) {
                                      return 'Please enter an Mobile Number';
                                    }
                                    if ((_edtxtNum.length < 10) &&
                                        (_edtxtNum.length > 10)) {
                                      return 'Please enter 10 digit Mobile Number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    var loaded = ref.watch(loadingProvider);
                                    return CoustEvalButton(
                                      onPressed: loaded == true
                                          ? null
                                          : () {
                                              ref
                                                  .read(phoneAuthProvider
                                                      .notifier)
                                                  .phoneAuth(
                                                      context,
                                                      _edtxtNum.text.trim(),
                                                      ref);
                                            },
                                      buttonName: "Verify",
                                      radius: 8,
                                      width: double.infinity,
                                      FontSize: 20,
                                      isLoading: loaded,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Consumer(
                            builder: (BuildContext context, WidgetRef ref,
                                Widget? child) {
                              var verfication = ref.watch(phoneAuthProvider);

                              return verfication.vrfCompleted == true
                                  ? Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Consumer(
                                            builder: (BuildContext context,
                                                WidgetRef ref, Widget? child) {
                                              return OTPTextField(
                                                onChanged: (value) {
                                                  print("Otp Value ${value}");
                                                  ref
                                                      .read(phoneAuthProvider
                                                          .notifier)
                                                      .updateOtp(value);
                                                },
                                                length: 6,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container();
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Consumer(
                              builder: (BuildContext context, WidgetRef ref,
                                  Widget? child) {
                                var loader = ref.watch(loadingProvider2);
                                return CoustEvalButton(
                                  onPressed: loader == true
                                      ? null
                                      : () {
                                          if (_validationkey.currentState!
                                              .validate()) {
                                            // print("OTP: ${ref.read(phoneAuthProvider).otp==null?"Null":ref.read(phoneAuthProvider).otp}");
                                            ref
                                                .read(
                                                    phoneAuthProvider.notifier)
                                                .signInWithPhoneNumber(
                                                    ref
                                                        .read(phoneAuthProvider)
                                                        .otp!,
                                                    context,
                                                    ref,
                                                    _edtxtNum.text.trim(),
                                                    false,
                                                    password: _edtxtpassword
                                                        .text
                                                        .trim(),
                                                    email:
                                                        _edtxtMail.text.trim(),
                                                    username:
                                                        _edtxtName.text.trim());
                                          }
                                        },
                                  FontSize: 20,
                                  radius: 8,
                                  width: double.infinity,
                                  buttonName: "Register",
                                  isLoading: loader,
                                );
                              },
                            ),
                          ),
                        ],
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
