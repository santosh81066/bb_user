import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Providers/withdrawal_provider.dart';

class WithdrawBottomSheet extends ConsumerStatefulWidget {
  final double currentBalance;
  final int userId;
  final Function(double amount, String method, String details)? onWithdraw;

  const WithdrawBottomSheet({
    super.key,
    required this.currentBalance,
    required this.userId,
    this.onWithdraw,
  });

  static void show(BuildContext context, {
    required double currentBalance,
    required int userId,
    Function(double amount, String method, String details)? onWithdraw,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => WithdrawBottomSheet(
        currentBalance: currentBalance,
        userId: userId,
        onWithdraw: onWithdraw,
      ),
    );
  }

  @override
  ConsumerState<WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends ConsumerState<WithdrawBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'amount': TextEditingController(),
    'upiId': TextEditingController(),
    'accountNumber': TextEditingController(),
    'ifsc': TextEditingController(),
    'accountHolder': TextEditingController(),
    'confirmAccount': TextEditingController(),
  };

  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;

  int _selectedMethod = 0; // 0: UPI, 1: Bank
  final _quickAmounts = [500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Validators
  String? _validateAmount(String? value) {
    if (value?.isEmpty ?? true) return 'Enter amount';
    final amount = double.tryParse(value!);
    if (amount == null) return 'Invalid amount';
    if (amount < 100) return 'Minimum ₹100';
    if (amount > widget.currentBalance) return 'Exceeds balance';
    return null;
  }

  String? _validateUpiId(String? value) {
    if (value?.isEmpty ?? true) return 'Enter UPI ID';
    if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$').hasMatch(value!)) {
      return 'Invalid UPI ID format';
    }
    return null;
  }

  String? _validateRequired(String? value, String field) =>
      (value?.isEmpty ?? true) ? 'Enter $field' : null;

  String? _validateAccount(String? value) {
    if (value?.isEmpty ?? true) return 'Enter account number';
    if (value!.length < 9 || value.length > 18) return '9-18 digits required';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only digits allowed';
    return null;
  }

  String? _validateIFSC(String? value) {
    if (value?.isEmpty ?? true) return 'Enter IFSC';
    final ifsc = value!.trim().toUpperCase();
    if (ifsc.length != 11) return 'IFSC must be 11 characters';
    if (!RegExp(r'^[A-Z]{4}[0-9][A-Z0-9]{6}$').hasMatch(ifsc)) {
      return 'Invalid IFSC format (e.g., SBIN0001234)';
    }
    return null;
  }

  String? _validateConfirmAccount(String? value) =>
      value != _controllers['accountNumber']!.text ? 'Numbers don\'t match' : null;

  void _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_controllers['amount']!.text);
    final method = _selectedMethod == 0 ? 'UPI' : 'Bank Transfer';
    final details = _selectedMethod == 0
        ? _controllers['upiId']!.text.trim()
        : '${_controllers['accountHolder']!.text.trim()} - '
        '${_controllers['accountNumber']!.text.trim()} - '
        '${_controllers['ifsc']!.text.trim().toUpperCase()}';

    // Call the withdrawal provider
    await ref.read(withdrawalControllerProvider.notifier).submitWithdrawal(
      amount: amount,
      method: method,
      details: details,
      userId: widget.userId,
    );

    // Also call the optional callback if provided
    if (widget.onWithdraw != null) {
      widget.onWithdraw!(amount, method, details);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    const primaryColor = Color(0xFF6418C3);

    // Listen to withdrawal state changes
    ref.listen<WithdrawalState>(withdrawalControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(withdrawalControllerProvider.notifier).clearMessages();
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(withdrawalControllerProvider.notifier).clearMessages();
        Navigator.of(context).pop();
      }
    });

    final withdrawalState = ref.watch(withdrawalControllerProvider);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - _slideAnimation.value) * 100),
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: DraggableScrollableSheet(
            initialChildSize: keyboardHeight > 0 ? 0.95 : 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  _buildHeader(primaryColor),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 20 : 100),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildAmountSection(primaryColor),
                            const SizedBox(height: 24),
                            _buildMethodSelector(primaryColor),
                            const SizedBox(height: 20),
                            _selectedMethod == 0 ? _buildUPIForm() : _buildBankForm(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (keyboardHeight == 0) _buildSubmitButton(primaryColor, withdrawalState.isLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) => Column(
    children: [
      Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        height: 4,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Withdraw Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Available Balance: ₹${widget.currentBalance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildAmountSection(Color primaryColor) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Withdrawal Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controllers['amount'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          validator: _validateAmount,
          decoration: _inputDecoration('Enter amount', Icons.currency_rupee, primaryColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _quickAmounts
              .where((amount) => amount <= widget.currentBalance)
              .map((amount) => GestureDetector(
            onTap: () => _controllers['amount']!.text = amount.toString(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text('₹${amount.toInt()}',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
            ),
          ))
              .toList(),
        ),
      ],
    ),
  );

  Widget _buildMethodSelector(Color primaryColor) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _buildMethodTab(0, Icons.account_balance_wallet, 'UPI', primaryColor),
        _buildMethodTab(1, Icons.account_balance, 'Bank', primaryColor),
      ],
    ),
  );

  Widget _buildMethodTab(int index, IconData icon, String label, Color primaryColor) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _selectedMethod == index ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: _selectedMethod == index ? Colors.white : Colors.grey.shade600,
                size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: _selectedMethod == index ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    ),
  );

  Widget _buildUPIForm() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UPI Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _controllers['upiId'],
          validator: _validateUpiId,
          decoration: _inputDecoration('yourname@paytm', Icons.account_balance_wallet,
              const Color(0xFF6418C3), label: 'UPI ID'),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(Icons.info_outline, 'Money will be transferred within 30 minutes', Colors.blue),
      ],
    ),
  );

  Widget _buildBankForm() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bank Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // Account Holder Name
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _controllers['accountHolder'],
            validator: (v) => _validateRequired(v, 'name'),
            textCapitalization: TextCapitalization.words,
            decoration: _inputDecoration(
                'Enter account holder name',
                Icons.person,
                const Color(0xFF6418C3),
                label: 'Account Holder Name'
            ),
          ),
        ),
        // Account Number
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _controllers['accountNumber'],
            validator: _validateAccount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
                'Enter account number',
                Icons.account_balance,
                const Color(0xFF6418C3),
                label: 'Account Number'
            ),
          ),
        ),
        // Confirm Account Number
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _controllers['confirmAccount'],
            validator: _validateConfirmAccount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
                'Enter account number again',
                Icons.verified,
                const Color(0xFF6418C3),
                label: 'Confirm Account Number'
            ),
          ),
        ),
        // IFSC Code
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _controllers['ifsc'],
            validator: _validateIFSC,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
                'SBIN0001234',
                Icons.code,
                const Color(0xFF6418C3),
                label: 'IFSC Code'
            ),
          ),
        ),
        _buildInfoCard(Icons.schedule, 'Bank transfers take 1-3 business days', Colors.orange),
      ],
    ),
  );

  Widget _buildInfoCard(IconData icon, String text, MaterialColor color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.shade200),
    ),
    child: Row(
      children: [
        Icon(icon, color: color.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color.shade700))),
      ],
    ),
  );

  Widget _buildSubmitButton(Color primaryColor, bool isLoading) => Container(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _processWithdrawal,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Text('Withdraw Money',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon, Color primaryColor, {String? label}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      );
}