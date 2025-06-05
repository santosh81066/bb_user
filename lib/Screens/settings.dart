// ignore_for_file: unused_import

import 'package:bb_user/Colors/coustcolors.dart';
import 'package:bb_user/Providers/theme_provider.dart';
import 'package:bb_user/Providers/language_provider.dart'; // Add this import
import 'package:bb_user/Screens/review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../L10n/app_localizations.dart';
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;
    try {
      setState(() {
        _isDeleting = true;
      });

      final authState = ref.read(authprovider);
      final userId = authState.userId;

      if (userId == null) {
        throw Exception("User ID not found");
      }

      final url = Uri.parse(Bbapi.login_mail);
      final request = http.Request("DELETE", url);
      request.headers.addAll({
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        "id": userId.toString(),  // must be a string!
      });

      print('Request body: ${request.body}');
      print('Sending DELETE to: $url');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('User ID type: ${userId.runtimeType}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await logout(context, ref);
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:Text('${localizations.failedToDeleteAccount}: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations?.error ?? 'Error'}: $error'),
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.deleteAccountTitle),
        content: Text(
          localizations.deleteAccountWarning,
          style: const TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(localizations.cancel),
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
                : Text(localizations.deleteAccount),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final currentLanguage = ref.read(languageProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations?.selectLanguage ?? 'Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLanguage.values.map((language) {
              return RadioListTile<AppLanguage>(
                title: Text(language.displayName),
                value: language,
                groupValue: currentLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(languageProvider.notifier).setLanguage(value);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${localizations?.languageChanged ?? 'Language changed to'} ${value.displayName}'),
                        backgroundColor: const Color(0xFF6418C3),
                      ),
                    );
                  }
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
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final currentTheme = ref.read(themeProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations?.selectTheme ?? 'Select Theme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeMode>(
                title: Text(localizations?.light ?? 'Light'),
                value: AppThemeMode.light,
                groupValue: currentTheme,
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(themeProvider.notifier).setTheme(value);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${localizations?.themeChanged ?? 'Theme changed to'} ${localizations?.light ?? 'Light'}'),
                        backgroundColor: const Color(0xFF6418C3),
                      ),
                    );
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                title: Text(localizations?.dark ?? 'Dark'),
                value: AppThemeMode.dark,
                groupValue: currentTheme,
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(themeProvider.notifier).setTheme(value);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${localizations?.themeChanged ?? 'Theme changed to'} ${localizations?.dark ?? 'Dark'}'),
                        backgroundColor: const Color(0xFF6418C3),
                      ),
                    );
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                title: Text(localizations?.systemDefault ?? 'System Default'),
                value: AppThemeMode.system,
                groupValue: currentTheme,
                onChanged: (value) async {
                  if (value != null) {
                    await ref.read(themeProvider.notifier).setTheme(value);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${localizations?.themeChanged ?? 'Theme changed to'} ${localizations?.systemDefault ?? 'System Default'}'),
                        backgroundColor: const Color(0xFF6418C3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(localizations?.cancel ?? 'Cancel'),
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
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6418C3),
        elevation: 0,
        title: Text(
          localizations?.settings ?? "Settings",
          style: const TextStyle(
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
          final themeNotifier = ref.read(themeProvider.notifier);
          final currentTheme = ref.watch(themeProvider);
          final currentLanguage = ref.watch(languageProvider);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: Text(
                      localizations?.account ?? "Account",
                      style: const TextStyle(
                        color: Color(0xFF6418C3),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSettingsCard(
                    icon: Icons.person_outline,
                    title: localizations?.profileSettings ?? "Profile Settings",
                    onTap: () => _navigateTo('/profile_settings'),
                  ),
                  _buildSettingsCard(
                    icon: Icons.wallet,
                    title: localizations?.wallet ?? "Wallet",
                    onTap: () => _navigateTo('/wallet'),
                  ),
                  _buildSettingsCard(
                    icon: Icons.receipt_long,
                    title: localizations?.paymentHistory ?? "Payment History",
                    onTap: () => _navigateTo('/payment_history'),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: Text(
                      localizations?.preferences ?? "Preferences",
                      style: const TextStyle(
                        color: Color(0xFF6418C3),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSettingsCard(
                    icon: Icons.notifications_none,
                    title: localizations?.notificationSettings ?? "Notification Settings",
                    onTap: () => _navigateTo('/notification_settings'),
                  ),
                  _buildSettingsCard(
                    icon: Icons.language,
                    title: localizations?.languages ?? "Languages",
                    subtitle: currentLanguage.displayName,
                    onTap: () => _showLanguageSelectionDialog(context, ref),
                  ),
                  _buildSettingsCard(
                    icon: Icons.color_lens_outlined,
                    title: localizations?.themes ?? "Themes",
                    subtitle: themeNotifier.themeDisplayName,
                    onTap: () => _showThemeSelectionDialog(context, ref),
                  ),
                  _buildSettingsCard(
                    icon: Icons.star_border,
                    title: localizations?.leaveReview ?? "Leave Review",
                    onTap: () => _navigateTo('/review'),
                    iconColor: CoustColors.colrEdtxt2,
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: Text(
                      localizations?.support ?? "Support",
                      style: const TextStyle(
                        color: Color(0xFF6418C3),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSettingsCard(
                    icon: Icons.help_outline,
                    title: localizations?.helpCenter ?? "Help Center",
                    onTap: () => _navigateTo('/help center'),
                  ),
                  _buildSettingsCard(
                    icon: Icons.contact_support_outlined,
                    title: localizations?.contactSupport ?? "Contact Support",
                    onTap: () => _navigateTo('/contact support'),
                  ),
                  _buildSettingsCard(
                    icon: Icons.privacy_tip_outlined,
                    title: localizations?.privacyPolicy ?? "Privacy Policy",
                    onTap: () => _navigateTo('/'),
                  ),
                  _buildSettingsCard(
                    icon: Icons.description_outlined,
                    title: localizations?.termsOfService ?? "Terms of Service",
                    onTap: () => _navigateTo('/'),
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: Text(
                      localizations?.session ?? "Session",
                      style: const TextStyle(
                        color: Color(0xFF6418C3),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildSettingsCard(
                    icon: Icons.delete_outline,
                    title: localizations?.deleteAccount ?? "Delete Account",
                    onTap: () => _showDeleteConfirmationDialog(context, ref),
                    textColor: CoustColors.colrEdtxt3,
                    iconColor: CoustColors.colrEdtxt3,
                  ),
                  _buildSettingsCard(
                    icon: Icons.logout,
                    title: localizations?.logout ?? "Logout",
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
    Color? iconColor,
    Color? textColor,
    bool withDivider = true,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200
        ),
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
                color: iconColor ?? Theme.of(context).iconTheme.color,
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
                        color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}