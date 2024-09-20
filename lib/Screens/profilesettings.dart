import 'dart:convert';

import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Providers/auth.dart';
import 'package:bb_user/Widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Widgets/evaluatedbutton.dart';

class ProfileSetingsScreen extends StatefulWidget {
  const ProfileSetingsScreen({super.key});

  @override
  State<ProfileSetingsScreen> createState() => _ProfileSetingsScreenState();
}

class _ProfileSetingsScreenState extends State<ProfileSetingsScreen> {
  final _validationkey = GlobalKey<FormState>();
  String sUsername = "Abc";
  String smail = "example123@email.com";
  String snum = "1234567800";
  final TextEditingController _dobController = TextEditingController();
  TextEditingController _edtxtMail = TextEditingController();
  final TextEditingController _edtxtName = TextEditingController();
  TextEditingController _edtxtNum = TextEditingController();
  TextEditingController _edtxtloc = TextEditingController();

  @override
  void initState() {
    super.initState();
    GetData();
    // _dobController.text =
    //     DateFormat('dd - MM - yyyy').format(DateTime(1990, 1, 1));
  }

  Future<void> GetData() async {
    final prefs = await SharedPreferences.getInstance();
    final extractData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    print("userDetails:${extractData}");
    setState(() {
      sUsername = extractData['username'];
      smail = extractData['email'];
      snum = extractData['mobileno'];
    });

    print(sUsername);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dobController.text = DateFormat('dd - MM - yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(sUsername);
    _edtxtName.text = sUsername;
    _edtxtNum.text = snum;
    _edtxtMail.text = smail;

    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Column(
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
                child: Text("Profile Settings",
                    style:
                        TextStyle(color: CoustColors.colrEdtxt4, fontSize: 20)),
              ),
            ),
            Form(
              key: _validationkey,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CoustTextfield(
                      isVisible: true,
                      title: "Name",
                      controller: _edtxtName,
                      inputtype: TextInputType.name,
                      hint: sUsername,
                      radius: 8,
                      width: 10,
                      validator: (_edtxtName) {
                        if (_edtxtName == null || _edtxtName.isEmpty) {
                          return 'Please enter Name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    CoustTextfield(
                      isVisible: true,
                      title: "Email",
                      controller: _edtxtMail,
                      inputtype: TextInputType.emailAddress,
                      hint: smail,
                      radius: 8,
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
                      isVisible: true,
                      title: "Phone Number",
                      controller: _edtxtNum,
                      inputtype: TextInputType.phone,
                      hint: snum,
                      radius: 8,
                      width: 10,
                      validator: (_edtxtNum) {
                        if (_edtxtNum == null || _edtxtNum.isEmpty) {
                          return 'Please enter Mobile Number';
                        }
                        if ((_edtxtNum.length < 10) &&
                            (_edtxtNum.length > 10)) {
                          return 'Please enter 10 digit Mobile Number';
                        }
                        return null;
                      },
                    ),
                    Visibility(
                        visible: false,
                        child: Container(
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Text("Date of Birth"),
                              SizedBox(
                                height: 5,
                              ),
                              TextFormField(
                                onTap: () {
                                  _selectDate(context);
                                },
                                controller: _dobController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(width: 10)),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text("Location"),
                              const SizedBox(
                                height: 5,
                              ),
                              TextFormField(
                                obscureText: false,
                                onTap: () {
                                  Navigator.of(context).pushNamed('/location');
                                },
                                controller: _edtxtloc,
                                decoration: const InputDecoration(
                                  hintText: "Hyderabad",
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(width: 10)),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                return CoustEvalButton(
                  onPressed: () {
                    if (_validationkey.currentState!.validate()) {
                      ref.read(authprovider.notifier).UserUpdate(
                          context,
                          _edtxtName.text.trim(),
                          _edtxtNum.text.trim(),
                          _edtxtMail.text.trim(),
                          ref);
                    }
                  },
                  buttonName: "Update",
                  radius: 8,
                  width: double.infinity,
                  FontSize: 20,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
