import 'dart:convert';
import 'dart:io';
import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Providers/auth.dart';
import 'package:bb_user/Widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Widgets/evaluatedbutton.dart';
import '../utils/bbapi.dart';

class ProfileSetingsScreen extends ConsumerStatefulWidget {
  const ProfileSetingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetingsScreen> createState() =>
      _ProfileSetingsScreenState();
}

class _ProfileSetingsScreenState extends ConsumerState<ProfileSetingsScreen>
    with TickerProviderStateMixin {
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

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _profileImageController;
  late AnimationController _buttonController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _profileImageAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Profile image animation controller
    _profileImageController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Button animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _profileImageAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileImageController,
      curve: Curves.elasticOut,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _profileImageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("=== Loading User Data ===");

      // First refresh the provider state
      await ref.read(authprovider.notifier).refreshUserData();

      // Then get the latest user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('userData')) {
        final extractData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
        print("Raw SharedPreferences data: $extractData");

        // Update the UI with this fresh data
        setState(() {
          sUsername = extractData['username'] ?? "";
          sEmail = extractData['email'] ?? "";
          sNum = extractData['mobile_no']?.toString() ?? "";
          profilePicUrl = extractData['profile_pic'];

          print("Extracted values:");
          print("  - sUsername: $sUsername");
          print("  - sEmail: $sEmail");
          print("  - sNum: $sNum");
          print("  - profilePicUrl: $profilePicUrl");

          _edtxtName.text = sUsername;
          _edtxtMail.text = sEmail;
          _edtxtNum.text = sNum;
        });

        // Start animations after data is loaded
        _startAnimations();
      } else {
        print("No userData found in SharedPreferences");
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _profileImageController.forward();
  }

  Future<void> _selectImage() async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImagePickerBottomSheet(),
    );
  }

  Widget _buildImagePickerBottomSheet() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.25,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Profile Picture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImagePickerOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _buildImagePickerOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF6418C3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: const Color(0xFF6418C3),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6418C3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
      // Animate profile image change
      _profileImageController.reset();
      _profileImageController.forward();
    }
  }

  Future<void> _handleProfileUpdate() async {
    if (_validationkey.currentState!.validate()) {
      // Button press animation
      await _buttonController.forward();
      await _buttonController.reverse();

      // Haptic feedback
      HapticFeedback.mediumImpact();

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

        // IMPORTANT: Clear profile image selection after successful upload
        setState(() {
          _profileImage = null;
        });

        // Force a small delay to ensure SharedPreferences has been updated
        await Future.delayed(Duration(milliseconds: 500));

        // Force refresh from SharedPreferences
        await ref.read(authprovider.notifier).refreshUserData();

        // After refreshing the provider, reload the UI data
        await _loadUserData();

        // Show a confirmation that data has been updated
        _showSuccessSnackBar();
      } catch (e) {
        print("Error updating profile: $e");
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Profile updated successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Error updating profile: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildProfileImage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.3;

    return AnimatedBuilder(
      animation: _profileImageAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _profileImageAnimation.value,
          child: GestureDetector(
            onTap: _selectImage,
            child: Hero(
              tag: 'profile_image',
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6418C3).withOpacity(0.3),
                      const Color(0xFF6418C3).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6418C3).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getProfileImage() == null ? Colors.grey[200] : null,
                      ),
                      child: _getProfileImage() != null
                          ? ClipOval(
                        child: Image(
                          image: _getProfileImage()!,
                          fit: BoxFit.cover,
                          width: imageSize,
                          height: imageSize,
                          errorBuilder: (context, error, stackTrace) {
                            print("Image loading error: $error");
                            return Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                              ),
                              child: Icon(
                                Icons.person,
                                size: imageSize * 0.5,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: const Color(0xFF6418C3),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                          : Icon(
                        Icons.person,
                        size: imageSize * 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: imageSize * 0.25,
                        height: imageSize * 0.25,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6418C3), Color(0xFF8A4FFF)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6418C3).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: imageSize * 0.12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  ImageProvider? _getProfileImage() {
    print("=== Profile Image Debug ===");
    print("_profileImage: $_profileImage");
    print("profilePicUrl: $profilePicUrl");

    // Only use local file if it exists AND we haven't uploaded it yet
    // After successful upload, _profileImage should be null
    if (_profileImage != null && _profileImage!.existsSync()) {
      print("Using local file image (newly selected)");
      return FileImage(_profileImage!);
    }

    // Use server profile picture
    if (profilePicUrl != null && profilePicUrl!.isNotEmpty) {
      String fullUrl = profilePicUrl!; // Your URL already seems complete

      print("Using server image URL: $fullUrl");
      return NetworkImage(fullUrl);
    }

    print("No profile image available");
    return null;
  }

  bool _showDefaultIcon() {
    return _profileImage == null && (profilePicUrl == null || profilePicUrl!.isEmpty);
  }

  Widget _buildAnimatedTextField({
    required String title,
    required TextEditingController controller,
    required TextInputType inputType,
    required String hint,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int delay = 0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.3 + (delay * 0.1)),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Interval(
              delay * 0.1,
              1.0,
              curve: Curves.easeOutCubic,
            ),
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _fadeController,
              curve: Interval(
                delay * 0.1,
                1.0,
                curve: Curves.easeIn,
              ),
            )),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: controller,
                      keyboardType: inputType,
                      obscureText: obscureText,
                      validator: validator,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFF2D3748),
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: screenWidth * 0.035,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6418C3),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.04,
                        ),
                        suffixIcon: suffixIcon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpdateButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
            )),
            child: Container(
              width: double.infinity,
              height: screenHeight * 0.07,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6418C3), Color(0xFF8A4FFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6418C3).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: _isLoading ? null : _handleProfileUpdate,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Update Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: _isLoading && sUsername.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Custom App Bar with gradient
          Container(
            width: double.infinity,
            height: screenHeight * 0.12,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6418C3), Color(0xFF8A4FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.01,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Profile Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _validationkey,
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.02),

                        // Profile Picture Section
                        _buildProfileImage(),
                        SizedBox(height: screenHeight * 0.04),

                        // Form Fields
                        _buildAnimatedTextField(
                          title: "Full Name",
                          controller: _edtxtName,
                          inputType: TextInputType.name,
                          hint: "Enter your full name",
                          delay: 1,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),

                        _buildAnimatedTextField(
                          title: "Email Address",
                          controller: _edtxtMail,
                          inputType: TextInputType.emailAddress,
                          hint: "Enter your email address",
                          delay: 2,
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

                        _buildAnimatedTextField(
                          title: "Phone Number",
                          controller: _edtxtNum,
                          inputType: TextInputType.phone,
                          hint: "Enter your phone number",
                          delay: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length != 10) {
                              return 'Please enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),

                        _buildAnimatedTextField(
                          title: "New Password",
                          controller: _edtxtPassword,
                          inputType: TextInputType.visiblePassword,
                          hint: "Leave empty to keep current password",
                          obscureText: !_showPassword,
                          delay: 4,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF6418C3),
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        // Update Button
                        _buildUpdateButton(),

                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}