import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/auth.dart';
import '../Providers/contactsupport.dart';

class ContactSupportPage extends ConsumerStatefulWidget {
  const ContactSupportPage({super.key});

  @override
  ConsumerState<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends ConsumerState<ContactSupportPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'subject': TextEditingController(),
    'message': TextEditingController(),
  };
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
    _prefillUserData();
  }

  void _prefillUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authprovider);
      if (authState.username?.isNotEmpty == true)
        _controllers['name']!.text = authState.username!;
      if (authState.email?.isNotEmpty == true)
        _controllers['email']!.text = authState.email!;
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authprovider);
    if (authState.userId == null) {
      _showSnackBar('Please log in to submit a support request', Colors.red,
          Icons.error_outline);
      return;
    }

    try {
      await ref.read(supportStateProvider.notifier).submitSupportRequest(
            fullname: _controllers['name']!.text,
            email: _controllers['email']!.text,
            subject: _controllers['subject']!.text,
            message: _controllers['message']!.text,
          );

      _showSnackBar(
          'Thank you ${_controllers['name']!.text}! Your support request has been submitted successfully.',
          Colors.green,
          Icons.check_circle);

      _controllers.values.forEach((c) => c.clear());
      _formKey.currentState!.reset();
      _prefillUserData();
    } catch (e) {
      _showSnackBar(
          'Failed to submit request: $e', Colors.red, Icons.error_outline);
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
                child:
                    Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportStateProvider);
    final authState = ref.watch(authprovider);
    final isSubmitting = supportState.isLoading;
    final isLoggedIn = authState.userId != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text('Contact Support',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                  if (!isLoggedIn) _buildWarningCard(),
                  _buildHeaderCard(authState),
                  const SizedBox(height: 30),
                  ..._buildFormFields(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(isSubmitting, isLoggedIn),
                  const SizedBox(height: 16),
                  _buildContactMethods(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard() => Container(
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
                    color: Colors.orange[700], fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  Widget _buildHeaderCard(authState) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 60, color: Color(0xFF6418C3)),
            const SizedBox(height: 16),
            const Text('How can we help you?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Fill out the form below and our support team will get back to you as soon as possible.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (authState.userId != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6418C3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Logged in as: ${authState.username ?? authState.email ?? 'User'}',
                    style: const TextStyle(
                        color: Color(0xFF6418C3),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      );

  List<Widget> _buildFormFields() {
    final fields = [
      {
        'label': 'Full Name',
        'controller': 'name',
        'hint': 'Enter your name',
        'icon': Icons.person_outline,
        'validator': 'name'
      },
      {
        'label': 'Email Address',
        'controller': 'email',
        'hint': 'Enter your email',
        'icon': Icons.email_outlined,
        'validator': 'email',
        'type': TextInputType.emailAddress
      },
      {
        'label': 'Subject',
        'controller': 'subject',
        'hint': 'What is this regarding?',
        'icon': Icons.subject,
        'validator': 'subject'
      },
    ];

    return [
      ...fields.expand((field) => [
            _buildInputLabel(field['label'] as String),
            _buildTextField(
              controller: _controllers[field['controller']]!,
              hintText: field['hint'] as String,
              prefixIcon: field['icon'] as IconData,
              keyboardType:
                  field['type'] as TextInputType? ?? TextInputType.text,
              validator: _getValidator(field['validator'] as String),
            ),
            const SizedBox(height: 20),
          ]),
      _buildInputLabel('Message'),
      _buildMessageField(),
    ];
  }

  String? Function(String?) _getValidator(String type) {
    switch (type) {
      case 'email':
        return (value) {
          if (value == null || value.isEmpty) return 'Please enter your email';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
            return 'Please enter a valid email address';
          return null;
        };
      default:
        return (value) =>
            value == null || value.isEmpty ? 'Please enter your ${type}' : null;
    }
  }

  Widget _buildInputLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(hintText, prefixIcon),
        validator: validator,
      );

  Widget _buildMessageField() => TextFormField(
        controller: _controllers['message']!,
        maxLines: 5,
        decoration: _inputDecoration(
            'Describe your issue or question in detail', Icons.message_outlined,
            isPadded: true),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter your message' : null,
      );

  InputDecoration _inputDecoration(String hintText, IconData icon,
          {bool isPadded = false}) =>
      InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: isPadded
            ? Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Icon(icon, color: Colors.grey[600]))
            : Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6418C3), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1)),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: isPadded ? 16 : 0),
      );

  Widget _buildSubmitButton(bool isSubmitting, bool isLoggedIn) => Center(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (isSubmitting || !isLoggedIn) ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6418C3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
                              color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Submitting...',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Text(
                    isLoggedIn ? 'Submit Request' : 'Please Log In',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      );

  Widget _buildContactMethods() => Center(
        child: Column(
          children: [
            Text('Or contact us directly:',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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
      );

  Widget _buildContactMethod(IconData icon, String label) => InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF6418C3), size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6418C3),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}
