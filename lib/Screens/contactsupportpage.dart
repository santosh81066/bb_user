import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/auth.dart';
import '../Providers/contactsupport.dart';

class ContactSupportPage extends ConsumerStatefulWidget {
  const ContactSupportPage({super.key});

  @override
  ConsumerState<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends ConsumerState<ContactSupportPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
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
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();

    // Pre-fill user data from auth state
    _prefillUserData();
  }

  void _prefillUserData() {
    // Get user data from auth state and pre-fill the form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authprovider);
      if (authState.username != null && authState.username!.isNotEmpty) {
        _nameController.text = authState.username!;
      }
      if (authState.email != null && authState.email!.isNotEmpty) {
        _emailController.text = authState.email!;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if user is authenticated
      final authState = ref.read(authprovider);
      if (authState.userId == null) {
        _showErrorMessage('Please log in to submit a support request');
        return;
      }

      try {
        // Submit the support request
        await ref.read(supportStateProvider.notifier).submitSupportRequestFormData(
          fullname: _nameController.text,
          email: _emailController.text,
          subject: _subjectController.text,
          message: _messageController.text,
        );

        // If we reach here, the request was successful
        _showSuccessMessage(_nameController.text);

        // Clear form fields
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();

        // Reset form
        _formKey.currentState!.reset();

        // Re-prefill user data
        _prefillUserData();

      } catch (e) {
        // Handle any errors that occurred during submission
        _showErrorMessage(e.toString());
      }
    }
  }

  void _showSuccessMessage(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Thank you $name! Your support request has been submitted successfully.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Failed to submit request: $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to supportStateProvider state and auth state
    final supportState = ref.watch(supportStateProvider);
    final authState = ref.watch(authprovider);

    // Check if currently submitting
    final isSubmitting = supportState.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Contact Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6418C3),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show authentication warning if not logged in
                  if (authState.userId == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please log in to submit a support request',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Header card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.support_agent,
                          size: 60,
                          color: Color(0xFF6418C3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'How can we help you?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Fill out the form below and our support team will get back to you as soon as possible.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Show current user info if logged in
                        if (authState.userId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6418C3).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Logged in as: ${authState.username ?? authState.email ?? 'User'}',
                                style: const TextStyle(
                                  color: Color(0xFF6418C3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Form fields
                  _buildInputLabel('Full Name'),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Enter your name',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildInputLabel('Email Address'),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildInputLabel('Subject'),
                  _buildTextField(
                    controller: _subjectController,
                    hintText: 'What is this regarding?',
                    prefixIcon: Icons.subject,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildInputLabel('Message'),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue or question in detail',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Icon(Icons.message_outlined, color: Colors.grey[600]),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6418C3), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Submit button
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (isSubmitting || authState.userId == null) ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6418C3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: isSubmitting
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Submitting...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          authState.userId == null ? 'Please Log In' : 'Submit Request',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Additional contact methods
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Or contact us directly:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildContactMethod(Icons.phone, 'Call'),
                            const SizedBox(width: 24),
                            _buildContactMethod(Icons.chat_bubble_outline, 'Live Chat'),
                            const SizedBox(width: 24),
                            _buildContactMethod(Icons.help_outline, 'FAQs'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6418C3), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildContactMethod(IconData icon, String label) {
    return InkWell(
      onTap: () {
        // Handle contact method tap
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6418C3),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6418C3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}