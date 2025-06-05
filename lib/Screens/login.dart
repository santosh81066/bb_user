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

  // Enhanced Device Type Detection
  DeviceType _getDeviceType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final diagonal = MediaQuery.of(context).size.shortestSide;

    // TV/Large Display Detection (width > 1920 or height > 1080)
    if (width > 1920 || height > 1080) {
      return DeviceType.tv;
    }
    // Desktop/Computer Detection
    else if (width > 1200 && diagonal > 600) {
      return DeviceType.desktop;
    }
    // Laptop Detection
    else if (width > 800 && width <= 1200 && diagonal > 600) {
      return DeviceType.laptop;
    }
    // Tablet Detection
    else if (diagonal > 600 && width > 600) {
      return DeviceType.tablet;
    }
    // Mobile Detection
    else {
      return DeviceType.mobile;
    }
  }

  // Get responsive dimensions based on device type
  ResponsiveDimensions _getResponsiveDimensions(BuildContext context) {
    final deviceType = _getDeviceType(context);
    final size = MediaQuery.of(context).size;

    switch (deviceType) {
      case DeviceType.mobile:
        return ResponsiveDimensions(
          horizontalPadding: 16.0,
          formPadding: 20.0,
          logoSize: 80.0,
          titleFontSize: 28.0,
          subtitleFontSize: 14.0,
          formTitleFontSize: 22.0,
          inputFontSize: 16.0,
          buttonHeight: 50.0,
          buttonFontSize: 16.0,
          formMaxWidth: double.infinity,
          verticalSpacing: 16.0,
          socialButtonSize: 45.0,
          socialIconSize: 22.0,
        );

      case DeviceType.tablet:
        return ResponsiveDimensions(
          horizontalPadding: 32.0,
          formPadding: 24.0,
          logoSize: 100.0,
          titleFontSize: 36.0,
          subtitleFontSize: 16.0,
          formTitleFontSize: 26.0,
          inputFontSize: 18.0,
          buttonHeight: 55.0,
          buttonFontSize: 18.0,
          formMaxWidth: 500.0,
          verticalSpacing: 20.0,
          socialButtonSize: 55.0,
          socialIconSize: 26.0,
        );

      case DeviceType.laptop:
        return ResponsiveDimensions(
          horizontalPadding: size.width * 0.15,
          formPadding: 28.0,
          logoSize: 120.0,
          titleFontSize: 42.0,
          subtitleFontSize: 18.0,
          formTitleFontSize: 28.0,
          inputFontSize: 18.0,
          buttonHeight: 60.0,
          buttonFontSize: 20.0,
          formMaxWidth: 450.0,
          verticalSpacing: 24.0,
          socialButtonSize: 60.0,
          socialIconSize: 28.0,
        );

      case DeviceType.desktop:
        return ResponsiveDimensions(
          horizontalPadding: size.width * 0.2,
          formPadding: 32.0,
          logoSize: 140.0,
          titleFontSize: 48.0,
          subtitleFontSize: 20.0,
          formTitleFontSize: 32.0,
          inputFontSize: 20.0,
          buttonHeight: 65.0,
          buttonFontSize: 22.0,
          formMaxWidth: 500.0,
          verticalSpacing: 28.0,
          socialButtonSize: 65.0,
          socialIconSize: 30.0,
        );

      case DeviceType.tv:
        return ResponsiveDimensions(
          horizontalPadding: size.width * 0.25,
          formPadding: 40.0,
          logoSize: 160.0,
          titleFontSize: 56.0,
          subtitleFontSize: 24.0,
          formTitleFontSize: 36.0,
          inputFontSize: 24.0,
          buttonHeight: 75.0,
          buttonFontSize: 26.0,
          formMaxWidth: 600.0,
          verticalSpacing: 32.0,
          socialButtonSize: 75.0,
          socialIconSize: 35.0,
        );
    }
  }

  // Get orientation-specific adjustments
  OrientationAdjustments _getOrientationAdjustments(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final deviceType = _getDeviceType(context);

    if (orientation == Orientation.landscape) {
      return OrientationAdjustments(
        useRow: deviceType == DeviceType.tablet ||
            deviceType == DeviceType.laptop ||
            deviceType == DeviceType.desktop ||
            deviceType == DeviceType.tv,
        logoPositionFactor: 0.3,
        formPositionFactor: 0.7,
        reduceVerticalSpacing: true,
      );
    }

    return OrientationAdjustments(
      useRow: false,
      logoPositionFactor: 1.0,
      formPositionFactor: 1.0,
      reduceVerticalSpacing: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceType = _getDeviceType(context);
    final dimensions = _getResponsiveDimensions(context);
    final orientationAdj = _getOrientationAdjustments(context);
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      backgroundColor: CoustColors.colrStrock1,
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
            height: orientation == Orientation.landscape
                ? size.height
                : (size.height < 600 ? 800 : size.height),
            child: Stack(
              children: [
                // Decorative elements - responsive
                _buildDecorativeElements(deviceType, size),

                // Main content
                if (orientationAdj.useRow && orientation == Orientation.landscape)
                  _buildLandscapeLayout(context, dimensions, orientationAdj)
                else
                  _buildPortraitLayout(context, dimensions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeElements(DeviceType deviceType, Size size) {
    double topCircleSize = 100;
    double bottomCircleSize = 150;

    switch (deviceType) {
      case DeviceType.mobile:
        topCircleSize = 100;
        bottomCircleSize = 150;
        break;
      case DeviceType.tablet:
        topCircleSize = 150;
        bottomCircleSize = 200;
        break;
      case DeviceType.laptop:
      case DeviceType.desktop:
        topCircleSize = 200;
        bottomCircleSize = 250;
        break;
      case DeviceType.tv:
        topCircleSize = 250;
        bottomCircleSize = 300;
        break;
    }

    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: topCircleSize,
            height: topCircleSize,
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
            width: bottomCircleSize,
            height: bottomCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CoustColors.colrButton2.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, ResponsiveDimensions dimensions) {
    return Column(
      children: [
        // Logo and title section
        _buildLogoSection(dimensions),

        Expanded(child: Container()),

        // Login form
        _buildLoginForm(context, dimensions),

        // Social login section
        _buildSocialLoginSection(dimensions),

        SizedBox(height: dimensions.verticalSpacing * 1.5),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ResponsiveDimensions dimensions, OrientationAdjustments orientationAdj) {
    return Row(
      children: [
        // Left side - Logo and title
        Expanded(
          flex: (orientationAdj.logoPositionFactor * 10).round(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoSection(dimensions),
            ],
          ),
        ),

        // Right side - Form
        Expanded(
          flex: (orientationAdj.formPositionFactor * 10).round(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLoginForm(context, dimensions),
              _buildSocialLoginSection(dimensions),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(ResponsiveDimensions dimensions) {
    return Column(
      children: [
        SizedBox(height: dimensions.verticalSpacing * 2),
        Image.asset(
          "assets/Banquetbookz.png",
          width: dimensions.logoSize,
          height: dimensions.logoSize,
        ),
        SizedBox(height: dimensions.verticalSpacing),
        Text(
          "BANQUET BOOKZ",
          style: TextStyle(
            fontSize: dimensions.titleFontSize,
            fontWeight: FontWeight.bold,
            color: CoustColors.colrFill,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: dimensions.verticalSpacing * 0.5),
        Text(
          "Book your perfect banquet experience",
          style: TextStyle(
            fontSize: dimensions.subtitleFontSize,
            color: CoustColors.colrStrock2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, ResponsiveDimensions dimensions) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: dimensions.horizontalPadding),
      padding: EdgeInsets.all(dimensions.formPadding),
      constraints: BoxConstraints(maxWidth: dimensions.formMaxWidth),
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
                // Form title
                Center(
                  child: Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: dimensions.formTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: CoustColors.colrMainText,
                    ),
                  ),
                ),
                SizedBox(height: dimensions.verticalSpacing * 0.3),
                Center(
                  child: Text(
                    "Sign in to continue",
                    style: TextStyle(
                      fontSize: dimensions.subtitleFontSize,
                      color: CoustColors.colrStrock2,
                    ),
                  ),
                ),
                SizedBox(height: dimensions.verticalSpacing * 1.5),

                // Email field
                TextFormField(
                  controller: _edtxtEmail,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: dimensions.inputFontSize,
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
                    contentPadding: EdgeInsets.symmetric(vertical: dimensions.verticalSpacing),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: dimensions.verticalSpacing),

                // Password field
                TextFormField(
                  controller: _edtxtPassword,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    fontSize: dimensions.inputFontSize,
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
                    contentPadding: EdgeInsets.symmetric(vertical: dimensions.verticalSpacing),
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
                      minimumSize: Size(0, dimensions.verticalSpacing * 2),
                    ),
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: CoustColors.colrHighlightedText,
                        fontWeight: FontWeight.w600,
                        fontSize: dimensions.inputFontSize * 0.875,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: dimensions.verticalSpacing),

                // Login button
                SizedBox(
                  height: dimensions.buttonHeight,
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
                      padding: EdgeInsets.symmetric(vertical: dimensions.verticalSpacing * 0.75),
                    ),
                    child: isLoading
                        ? SizedBox(
                      width: dimensions.buttonHeight * 0.4,
                      height: dimensions.buttonHeight * 0.4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: dimensions.buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: dimensions.verticalSpacing * 1.5),

                // Sign up option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: dimensions.inputFontSize * 0.875,
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
                          fontSize: dimensions.inputFontSize * 0.875,
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
    );
  }

  Widget _buildSocialLoginSection(ResponsiveDimensions dimensions) {
    return Column(
      children: [
        SizedBox(height: dimensions.verticalSpacing * 1.5),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: dimensions.horizontalPadding),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Or continue with",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dimensions.subtitleFontSize,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
        SizedBox(height: dimensions.verticalSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialLoginButton(Icons.g_mobiledata, CoustColors.colrButton3, dimensions),
            SizedBox(width: dimensions.verticalSpacing),
            _socialLoginButton(Icons.facebook, CoustColors.colrButton3, dimensions),
            SizedBox(width: dimensions.verticalSpacing),
            _socialLoginButton(Icons.apple, CoustColors.colrButton3, dimensions),
          ],
        ),
      ],
    );
  }

  Widget _socialLoginButton(IconData icon, Color color, ResponsiveDimensions dimensions) {
    return Container(
      width: dimensions.socialButtonSize,
      height: dimensions.socialButtonSize,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: dimensions.socialIconSize),
        onPressed: () {
          // TODO: Implement social login
        },
      ),
    );
  }
}

// Device Type Enum
enum DeviceType {
  mobile,
  tablet,
  laptop,
  desktop,
  tv,
}

// Responsive Dimensions Class
class ResponsiveDimensions {
  final double horizontalPadding;
  final double formPadding;
  final double logoSize;
  final double titleFontSize;
  final double subtitleFontSize;
  final double formTitleFontSize;
  final double inputFontSize;
  final double buttonHeight;
  final double buttonFontSize;
  final double formMaxWidth;
  final double verticalSpacing;
  final double socialButtonSize;
  final double socialIconSize;

  ResponsiveDimensions({
    required this.horizontalPadding,
    required this.formPadding,
    required this.logoSize,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.formTitleFontSize,
    required this.inputFontSize,
    required this.buttonHeight,
    required this.buttonFontSize,
    required this.formMaxWidth,
    required this.verticalSpacing,
    required this.socialButtonSize,
    required this.socialIconSize,
  });
}

// Orientation Adjustments Class
class OrientationAdjustments {
  final bool useRow;
  final double logoPositionFactor;
  final double formPositionFactor;
  final bool reduceVerticalSpacing;

  OrientationAdjustments({
    required this.useRow,
    required this.logoPositionFactor,
    required this.formPositionFactor,
    required this.reduceVerticalSpacing,
  });
}