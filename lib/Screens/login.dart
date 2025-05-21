import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Colors/coustcolors.dart';
import '../Providers/auth.dart';
import '../Providers/loaded.dart';

class ResponsiveLoginScreen extends ConsumerStatefulWidget {
  const ResponsiveLoginScreen({super.key});

  @override
  ConsumerState<ResponsiveLoginScreen> createState() => _ResponsiveLoginScreenState();
}

class _ResponsiveLoginScreenState extends ConsumerState<ResponsiveLoginScreen> {
  final _validationkey = GlobalKey<FormState>();
  final TextEditingController _edtxtEmail = TextEditingController();
  final TextEditingController _edtxtPassword = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _edtxtEmail.dispose();
    _edtxtPassword.dispose();
    super.dispose();
  }

  // Get responsive sizing based on screen width
  double _getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  // Get responsive font size based on screen width
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return baseSize * 1.2; // Large screens
    } else if (screenWidth > 600) {
      return baseSize * 1.0; // Medium screens
    } else {
      return baseSize * 0.9; // Small screens
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;
    final isLargeScreen = size.width >= 1200;

    return Scaffold(
      backgroundColor:CoustColors.colrStrock1,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black26,
              CoustColors.colrFill,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: isSmallScreen ? 100 : 150,
                    height: isSmallScreen ? 100 : 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CoustColors.colrHighlightedText.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: -50,
                  child: Container(
                    width: isSmallScreen ? 150 : 200,
                    height: isSmallScreen ? 150 : 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CoustColors.colrButton2.withOpacity(0.1),
                    ),
                  ),
                ),

                Column(
                  children: [
                    // App logo or title
                    SizedBox(height: isSmallScreen ? 60 : 80),
                    Image.asset(
                      "assets/app_icon.jpg",
                      width: isSmallScreen ? 80 : 120,
                      height: isSmallScreen ? 80 : 120,

                    ),
                    SizedBox(height: isSmallScreen ? 15 : 20),
                    Text(
                      "BANQUET BOOKZ",
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 32),
                        fontWeight: FontWeight.bold,
                        color: CoustColors.colrFill,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Book your perfect banquet experience",
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 16),
                        color: CoustColors.colrStrock2,
                      ),
                    ),

                    Expanded(child: Container()),

                    // Login form
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : (isMediumScreen ? 24 : _getResponsiveWidth(context, 0.2)),
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      width: isLargeScreen ? _getResponsiveWidth(context, 0.4) : double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _validationkey,
                        child: Consumer(
                          builder: (BuildContext context, WidgetRef ref, Widget? child) {
                            var isLoading = ref.watch(loadingProvider.notifier).state;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    "Welcome Back",
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(context, 24),
                                      fontWeight: FontWeight.bold,
                                      color: CoustColors.colrMainText,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    "Sign in to continue",
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(context, 16),
                                      color: CoustColors.colrStrock2,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 24 : 32),

                                // Email field with custom styling
                                TextFormField(
                                  controller: _edtxtEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(context, 16),
                                    color: CoustColors.colrMainText,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Email Address",
                                    labelStyle: TextStyle(color: Colors.black87),
                                    hintText: "Enter your email",
                                    hintStyle: TextStyle(color: Colors.black87),
                                    prefixIcon: Icon(Icons.email_outlined, color: CoustColors.colrHighlightedText),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: CoustColors.colrStrock1, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: CoustColors.colrFill,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email address';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Password field with custom styling
                                TextFormField(
                                  controller: _edtxtPassword,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(context, 16),
                                    color: CoustColors.colrMainText,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    labelStyle: TextStyle(color: Colors.black87),
                                    hintText: "Enter your password",
                                    hintStyle: TextStyle(color: Colors.black87),
                                    prefixIcon: Icon(Icons.lock_outline, color: CoustColors.colrHighlightedText),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: CoustColors.colrEdtxt1,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: CoustColors.colrStrock1, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: CoustColors.colrFill,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // TODO: Add forgot password functionality
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 35),
                                    ),
                                    child: Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: CoustColors.colrHighlightedText,
                                        fontWeight: FontWeight.w600,
                                        fontSize: _getResponsiveFontSize(context, 14),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Login button
                                SizedBox(
                                  height: isSmallScreen ? 50 : 55,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                      if (_validationkey.currentState?.validate() ?? false) {
                                        ref.read(loadingProvider.notifier).state = true;
                                        try {
                                          await ref.read(authprovider.notifier).loginmail(
                                              context,
                                              _edtxtEmail.text.trim(),
                                              _edtxtPassword.text.trim(),
                                              ref
                                          );
                                        } catch (e) {
                                          print("Login failed: $e");
                                        } finally {
                                          ref.read(loadingProvider.notifier).state = false;
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: CoustColors.colrButton3,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: _getResponsiveFontSize(context, 18),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 20 : 24),

                                // Sign up option
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: _getResponsiveFontSize(context, 14),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/registration');
                                      },
                                      child: Text(
                                        "Create Account",
                                        style: TextStyle(
                                          color: CoustColors.colrHighlightedText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: _getResponsiveFontSize(context, 14),
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

                    // Social login options
                    SizedBox(height: isSmallScreen ? 20 : 30),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : (isMediumScreen ? 24 : _getResponsiveWidth(context, 0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Or continue with",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveFontSize(context, 14),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialLoginButton(Icons.g_mobiledata, CoustColors.colrButton3),
                        const SizedBox(width: 16),
                        _socialLoginButton(Icons.facebook, CoustColors.colrButton3),
                        const SizedBox(width: 16),
                        _socialLoginButton(Icons.apple, CoustColors.colrButton3),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 30 : 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialLoginButton(IconData icon, Color color) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Container(
      width: isSmallScreen ? 50 : 60,
      height: isSmallScreen ? 50 : 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: isSmallScreen ? 25 : 30),
        onPressed: () {
          // TODO: Implement social login
        },
      ),
    );
  }
}