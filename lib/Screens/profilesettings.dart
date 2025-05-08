import 'dart:convert';
import 'dart:io';

import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Providers/auth.dart';
import 'package:bb_user/Widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Widgets/evaluatedbutton.dart';

class ProfileSetingsScreen extends ConsumerStatefulWidget {
  const ProfileSetingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetingsScreen> createState() =>
      _ProfileSetingsScreenState();
}

class _ProfileSetingsScreenState extends ConsumerState<ProfileSetingsScreen> {
  final _validationkey = GlobalKey<FormState>();
  String sUsername = "";
  String sEmail = "";
  String sNum = "";
  String? profilePicUrl;

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First refresh the provider state
      await ref.read(authprovider.notifier).refreshUserData();

      // Then get the latest user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('userData')) {
        final extractData =
            json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
        print("User data loaded after refresh: $extractData");

        // Update the UI with this fresh data
        setState(() {
          sUsername = extractData['username'] ?? "";
          sEmail = extractData['email'] ?? "";
          sNum = extractData['mobile_no'] ?? "";
          profilePicUrl = extractData['profile_pic'];

          _edtxtName.text = sUsername;
          _edtxtMail.text = sEmail;
          _edtxtNum.text = sNum;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _handleProfileUpdate() async {
    if (_validationkey.currentState!.validate()) {
      // Show loading indicator
      setState(() => _isLoading = true);

      try {
        // Call the update method
        await ref.read(authprovider.notifier).updateUserProfile(
            context,
            _edtxtName.text.trim(),
            _edtxtNum.text.trim(),
            _edtxtMail.text.trim(),
            _edtxtPassword.text.isEmpty ? null : _edtxtPassword.text,
            _profileImage,
            ref);

        // Clear password field after update
        _edtxtPassword.clear();

        // Reset profile image selection
        setState(() {
          _profileImage = null;
        });

        // Force a small delay to ensure SharedPreferences has been updated
        await Future.delayed(Duration(milliseconds: 300));

        // Force refresh from SharedPreferences
        await ref.read(authprovider.notifier).refreshUserData();

        // After refreshing the provider, reload the UI data
        await _loadUserData();

        // Show a confirmation that data has been updated
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        print("Error updating profile: $e");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                        : (profilePicUrl != null &&
                                                profilePicUrl!.isNotEmpty
                                            ? NetworkImage(profilePicUrl!)
                                            : null),
                                    child: (_profileImage == null &&
                                            (profilePicUrl == null ||
                                                profilePicUrl!.isEmpty))
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
                            onPressed: _handleProfileUpdate,
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
}
