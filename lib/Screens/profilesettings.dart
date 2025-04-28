import 'dart:convert';
import 'dart:io';

import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Providers/auth.dart';
import 'package:bb_user/Widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../Widgets/evaluatedbutton.dart';

class ProfileSetingsScreen extends ConsumerStatefulWidget {
  const ProfileSetingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetingsScreen> createState() =>
      _ProfileSetingsScreenState();
}

class _ProfileSetingsScreenState extends ConsumerState<ProfileSetingsScreen> {
  final _validationkey = GlobalKey<FormState>();
  final TextEditingController _edtxtName = TextEditingController();
  final TextEditingController _edtxtNum = TextEditingController();
  final TextEditingController _edtxtMail = TextEditingController();
  final TextEditingController _edtxtPassword = TextEditingController();

  File? _profileImage;
  bool _isLoading = true;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Set a very short delay to ensure the widget is fully mounted
    Future.microtask(() {
      _initializeControllers();
    });
  }

  // Initialize controllers with current auth state data
  void _initializeControllers() {
    final authState = ref.read(authprovider);

    setState(() {
      _edtxtName.text = authState.username ?? "";
      _edtxtMail.text = authState.email ?? "";
      _edtxtNum.text = authState.mobileno ?? "";
      _isLoading = false;
    });
  }

  // Update controllers when auth state changes
  void _updateControllersFromState() {
    final authState = ref.read(authprovider);

    _edtxtName.text = authState.username ?? "";
    _edtxtMail.text = authState.email ?? "";
    _edtxtNum.text = authState.mobileno ?? "";
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth state to rebuild when it changes
    final authState = ref.watch(authprovider);

    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 90,
                    decoration: const BoxDecoration(
                        color: Color(0xFF6418C3),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadiusDirectional.only(
                            bottomEnd: Radius.circular(25),
                            bottomStart: Radius.circular(25))),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 20.0, left: 15),
                      child: Text("Profile Settings",
                          style: TextStyle(
                              color: CoustColors.colrEdtxt4, fontSize: 20)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Form(
                      key: _validationkey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture Section
                          Center(
                            child: GestureDetector(
                              onTap: _selectImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                            as ImageProvider
                                        : (authState.profilePic != null &&
                                                authState.profilePic!.isNotEmpty
                                            ? NetworkImage(
                                                authState.profilePic!)
                                            : null),
                                    child: (_profileImage == null &&
                                            (authState.profilePic == null ||
                                                authState.profilePic!.isEmpty))
                                        ? const Icon(Icons.person,
                                            size: 60, color: Colors.grey)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Username field
                          CoustTextfield(
                            isVisible: true,
                            title: "Name",
                            controller: _edtxtName,
                            inputtype: TextInputType.name,
                            hint: "Enter username",
                            radius: 8,
                            width: 10,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter Name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Email field
                          CoustTextfield(
                            isVisible: true,
                            title: "Email",
                            controller: _edtxtMail,
                            inputtype: TextInputType.emailAddress,
                            hint: "Enter email",
                            radius: 8,
                            width: 10,
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
                          const SizedBox(height: 15),

                          // Phone number field
                          CoustTextfield(
                            isVisible: true,
                            title: "Phone Number",
                            controller: _edtxtNum,
                            inputtype: TextInputType.phone,
                            hint: "Enter phone number",
                            radius: 8,
                            width: 10,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter Mobile Number';
                              }
                              if (value.length != 10) {
                                return 'Please enter 10 digit Mobile Number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // Password field (for changing password)
                          TextFormField(
                            controller: _edtxtPassword,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: "New Password (Optional)",
                              hintText: "Leave empty to keep current password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              // Password validation only if a value is provided
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          // Update button
                          CoustEvalButton(
                            onPressed: () async {
                              if (_validationkey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });

                                await ref
                                    .read(authprovider.notifier)
                                    .updateUserProfile(
                                      context,
                                      _edtxtName.text.trim(),
                                      _edtxtNum.text.trim(),
                                      _edtxtMail.text.trim(),
                                      _edtxtPassword.text.isEmpty
                                          ? null
                                          : _edtxtPassword.text,
                                      _profileImage,
                                      ref,
                                    );

                                // Force refresh SharedPreferences data here
                                await ref
                                    .read(authprovider.notifier)
                                    .tryAutoLogin();

                                setState(() {
                                  _isLoading = false;
                                  // Clear the selected profile image after update
                                  _profileImage = null;
                                  // Clear the password field
                                  _edtxtPassword.clear();
                                });
                              }
                            },
                            buttonName: "Update",
                            radius: 8,
                            width: double.infinity,
                            FontSize: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures we update controllers when auth state changes
    // or when navigating back to this screen
    _updateControllersFromState();
  }

  @override
  void dispose() {
    _edtxtName.dispose();
    _edtxtNum.dispose();
    _edtxtMail.dispose();
    _edtxtPassword.dispose();
    super.dispose();
  }
}
