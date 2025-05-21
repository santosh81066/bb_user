  // ignore_for_file: unused_import

  import 'package:bb_user/Colors/coustcolors.dart';
  import 'package:bb_user/Screens/review.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';

  import '../Providers/auth.dart';
  import '../Providers/loaded.dart';
  import '../Widgets/text.dart';
  import '../utils/bbapi.dart';

  class SettingsScreen extends StatefulWidget {
    const SettingsScreen({super.key});

    @override
    State<SettingsScreen> createState() => _SettingsScreenState();
  }

  class _SettingsScreenState extends State<SettingsScreen> {
    bool _isDeleting = false;
    String _selectedLanguage = 'English';
    String _selectedTheme = 'Light';

    final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
    final List<String> _themes = ['Light', 'Dark', 'System Default'];

    Future<void> logout(BuildContext context, WidgetRef ref) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('SharedPreferences cleared');
      ref.read(authprovider.notifier).clear();
      ref.read(enablepasswaorProvider.notifier).state = false;
      if (!prefs.containsKey('userData')) {
        print('trylogin is false');
        // Navigator.pushNamed(context, '/');
      }
    }

    Future<void> deleteAccount(BuildContext context, WidgetRef ref) async {
      try {
        setState(() {
          _isDeleting = true;
        });

        // Get user ID from auth provider
        final authState = ref.read(authprovider);
        final userId = authState.userId;

        if (userId == null) {
          throw Exception("User ID not found");
        }

        // Make API call to delete account
        final response = await http.delete(
          Uri.parse(Bbapi.login_mail),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "id": userId,
          }),
        );

        if (response.statusCode == 200) {
          // Account deleted successfully, now log out
          await logout(context, ref);

          // Navigate to login or landing page
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (error) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }

    void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Warning: This action will permanently delete your account and all associated data. This action cannot be undone. Are you sure you want to proceed?',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: _isDeleting
                  ? null
                  : () {
                Navigator.of(ctx).pop();
                deleteAccount(context, ref);
              },
              child: _isDeleting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      );
    }

    void _showLanguageSelectionDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _languages.map((language) {
                return RadioListTile<String>(
                  title: Text(language),
                  value: language,
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Navigator.of(ctx).pop();
                    // Here you can implement language change logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to $value'),
                        backgroundColor: const Color(0xFF6418C3),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    void _showThemeSelectionDialog() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Theme'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _themes.map((theme) {
                return RadioListTile<String>(
                  title: Text(theme),
                  value: theme,
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                    Navigator.of(ctx).pop();
                    // Here you can implement theme change logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Theme changed to $value'),
                        backgroundColor: const Color(0xFF6418C3),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    void _navigateTo(String route) {
      Navigator.pushNamed(context, route);
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF6418C3),
          elevation: 0,
          title: const Text(
            "Settings",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        body: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                      child: Text(
                        "Account",
                        style: TextStyle(
                          color: Color(0xFF6418C3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildSettingsCard(
                      icon: Icons.person_outline,
                      title: "Profile Settings",
                      onTap: () => _navigateTo('/profile_settings'),
                    ),
                    _buildSettingsCard(
                      icon: Icons.wallet,
                      title: "Wallet",
                      onTap: () => _navigateTo('/wallet'),
                    ),
                    _buildSettingsCard(
                      icon: Icons.receipt_long,
                      title: "Payment History",
                      onTap: () => _navigateTo('/payment_history'),
                    ),

                    const SizedBox(height: 24),

                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                      child: Text(
                        "Preferences",
                        style: TextStyle(
                          color: Color(0xFF6418C3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildSettingsCard(
                      icon: Icons.notifications_none,
                      title: "Notification Settings",
                      onTap: () => _navigateTo('/notification_settings'),
                    ),
                    _buildSettingsCard(
                      icon: Icons.language,
                      title: "Languages",
                      subtitle: _selectedLanguage,
                      onTap: _showLanguageSelectionDialog,
                    ),
                    _buildSettingsCard(
                      icon: Icons.color_lens_outlined,
                      title: "Themes",
                      subtitle: _selectedTheme,
                      onTap: _showThemeSelectionDialog,
                    ),
                    _buildSettingsCard(
                      icon: Icons.star_border,
                      title: "Leave Review",
                      onTap: () => _navigateTo('/review'),
                      iconColor: CoustColors.colrEdtxt2,
                    ),
                    const SizedBox(height: 24),

                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                      child: Text(
                        "Support",
                        style: TextStyle(
                          color: Color(0xFF6418C3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildSettingsCard(
                      icon: Icons.help_outline,
                      title: "Help Center",
                      onTap: () => _navigateTo('/help center'),
                    ),
                    _buildSettingsCard(
                      icon: Icons.contact_support_outlined,
                      title: "Contact Support",
                      onTap: () => _navigateTo('/contact support'),
                    ),
                    _buildSettingsCard(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () => _navigateTo('/privacy_policy'),
                    ),
                    _buildSettingsCard(
                      icon: Icons.description_outlined,
                      title: "Terms of Service",
                      onTap: () => _navigateTo('/terms_of_service'),
                    ),
                    const SizedBox(height: 24),

                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
                      child: Text(
                        "Session",
                        style: TextStyle(
                          color: Color(0xFF6418C3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildSettingsCard(
                      icon: Icons.delete_outline,
                      title: "Delete Account",
                      onTap: () => _showDeleteConfirmationDialog(context, ref),
                      textColor: CoustColors.colrEdtxt3,
                      iconColor: CoustColors.colrEdtxt3,
                    ),
                    _buildSettingsCard(
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: () => logout(context, ref),
                      withDivider: false,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    Widget _buildSettingsCard({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      String? subtitle,
      Color iconColor = Colors.black87,
      Color? textColor,
      bool withDivider = true,
    }) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor ?? iconColor,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }