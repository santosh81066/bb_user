// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Widgets/evaluatedbutton.dart';
import '../Widgets/heading.dart';
import '../Widgets/textfield.dart';
import 'dart:io';

import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Providers/registrationnotifier.dart';
import 'package:bb_user/models/registrationstatemodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bb_user/Widgets/text.dart';

// Step 1: Define the StateNotifierProvider
final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier();
});

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> with SingleTickerProviderStateMixin {
  // Controllers for input fields
  final TextEditingController _edtxtMail = TextEditingController();
  final TextEditingController _edtxtName = TextEditingController();
  final TextEditingController _edtxtPassword = TextEditingController();
  final TextEditingController _edtxtConfirmPassword = TextEditingController();
  final TextEditingController _edtxtNum = TextEditingController();

  final _validationKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _edtxtMail.dispose();
    _edtxtName.dispose();
    _edtxtPassword.dispose();
    _edtxtConfirmPassword.dispose();
    _edtxtNum.dispose();
    super.dispose();
  }

  // Password validation function
  bool isValidPassword(String value) {
    final RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(value);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image for better performance
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Check the file size (maximum 2MB)
        final fileSizeInBytes = await imageFile.length();
        final maxFileSize = 2 * 1024 * 1024; // 2MB in bytes

        if (fileSizeInBytes > maxFileSize) {
          // File size is too large, show an error
          _showSnackBar('File size exceeds 2MB. Please select a smaller file.');
        } else {
          // Valid image size, proceed
          setState(() {
            _profileImage = imageFile;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imagePickerButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _imagePickerButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_profileImage != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _profileImage = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Remove Photo',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: CoustColors.colrButton1.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: CoustColors.colrButton1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _profileImage != null ? Colors.transparent : CoustColors.colrButton1.withOpacity(0.1),
          borderRadius: BorderRadius.circular(75),
          border: Border.all(
            color: CoustColors.colrButton1,
            width: 2,
          ),
        ),
        child: _profileImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(75),
          child: Image.file(
            _profileImage!,
            fit: BoxFit.cover,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 30,
              color: CoustColors.colrButton1,
            ),
            const SizedBox(height: 5),
            Text(
              "Add Photo",
              style: TextStyle(
                fontSize: 12,
                color: CoustColors.colrButton1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool toggleVisibility = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !toggleVisibility,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: CoustColors.colrButton1),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              toggleVisibility ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFA28AC6),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CoustColors.colrStrock1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Please fill the details to register",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildImageUploadSection(),
                  const SizedBox(height: 30),
                  Form(
                    key: _validationKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _edtxtName,
                          hint: "Full Name",
                          icon: Icons.person,
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        _buildInputField(
                          controller: _edtxtMail,
                          hint: "Email Address",
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
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
                        _buildInputField(
                          controller: _edtxtNum,
                          hint: "Phone Number",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a phone number';
                            } else if (value.length != 10) {
                              return 'Please enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                        _buildInputField(
                          controller: _edtxtPassword,
                          hint: "Password",
                          icon: Icons.lock,
                          isPassword: true,
                          toggleVisibility: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            } else if (!isValidPassword(value)) {
                              return 'Password must have at least 8 characters with letters and numbers';
                            }
                            return null;
                          },
                        ),
                        _buildInputField(
                          controller: _edtxtConfirmPassword,
                          hint: "Confirm Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          toggleVisibility: _isConfirmPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value != _edtxtPassword.text.trim()) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  Consumer(
                    builder: (context, ref, child) {
                      final registrationState = ref.watch(registrationProvider);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: registrationState.isLoading
                                ? null
                                : () async {
                              if (_validationKey.currentState!.validate()) {
                                ref.read(registrationProvider.notifier).register(
                                  context,
                                  _edtxtName.text.trim(),
                                  _edtxtMail.text.trim(),
                                  _edtxtPassword.text.trim(),
                                  _edtxtNum.text.trim(),
                                  _profileImage,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CoustColors.colrButton3,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 2,
                            ),
                            child: registrationState.isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}