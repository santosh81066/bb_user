import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Providers/auth.dart';
import '../Providers/wallet.dart';
import '../Providers/firebase.dart';
import '../Widgets/withdraw.dart';


class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountController = TextEditingController(text: '10');
  final _firebaseService = FirebaseRealtimeService();
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupRazorpay();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _firebaseService.ensureAuthenticated();
      _loadWalletData();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _setupRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) =>
        _showSnackBar('Payment failed: ${response.message}'));
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) =>
        _showSnackBar('External wallet: ${response.walletName}'));
  }

  Future<void> _loadWalletData() async {
    await ref.read(walletProvider.notifier).loadWalletData();
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _showSnackBar('Payment successful, updating wallet...');

    final amount = double.tryParse(_amountController.text);
    if (amount != null) {
      try {
        final success = await ref.read(walletProvider.notifier).addToWallet(amount);
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadWalletData();

        _showSnackBar(success
            ? '₹$amount added! Payment ID: ${response.paymentId}'
            : ref.read(walletProvider).error ?? 'Failed to add money');
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}');
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _startPayment() {
    // Get user data from auth provider instead of Firebase
    final authState = ref.read(authprovider);

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount');
      return;
    }

    try {
      _razorpay.open({
        'key': 'rzp_live_4mzpwZrJggHKRm',
        'amount': (amount * 100).toInt(),
        'name': 'Wallet Top-up',
        'description': 'Add Money to Wallet',
        'prefill': {
          'contact': authState.mobileno ?? '9123456789',
          'email': authState.email ?? 'test@example.com'
        },
        'theme': {'color': '#6418C3'},
      });
    } catch (e) {
      _showSnackBar('Failed to open payment: $e');
    }
  }

  void _showWithdrawDialog() {
    final balance = ref.read(walletProvider).balance;
    if (balance < 100) {
      _showSnackBar('Minimum ₹100 required for withdrawal', color: Colors.orange);
      return;
    }

    // Get user data from auth provider instead of Firebase
    final authState = ref.read(authprovider);
    final userId = authState.userId;

    if (userId == null) {
      _showSnackBar('User not authenticated', color: Colors.red);
      return;
    }

    // Show the bottom sheet with userId from auth provider
    WithdrawBottomSheet.show(
      context,
      currentBalance: balance,
      userId: userId, // This is already an int from your auth system
      onWithdraw: _processWithdrawal,
    );
  }

  Future<void> _processWithdrawal(double amount, String method, String bankDetails) async {
    try {
      _showSnackBar('Processing withdrawal request...');

      final success = await ref
          .read(walletProvider.notifier)
          .makePayment(amount, 'Withdrawal to $method - $bankDetails');

      await Future.delayed(const Duration(milliseconds: 1000));
      await _loadWalletData();

      _showSnackBar(success
          ? 'Withdrawal of ₹$amount submitted!\nProcessing time: 1-3 business days'
          : ref.read(walletProvider).error ?? 'Withdrawal failed',
          color: success ? Colors.green : Colors.red);
    } catch (e) {
      _showSnackBar('Error: $e', color: Colors.red);
    }
  }

  Future<void> _refreshWallet() async {
    await _loadWalletData();
    _showSnackBar('Wallet refreshed');
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final authState = ref.watch(authprovider); // Watch auth state for user info
    final isLoading = walletState.isLoading || _isProcessing;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6418C3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            'Wallet - ${authState.username ?? "User"}', // Show username from auth
            style: const TextStyle(color: Colors.white)
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : _refreshWallet,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshWallet,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header decoration
              Container(
                width: double.infinity,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFF6418C3),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // User Info Card (Optional - shows auth user data)
              _buildUserInfoCard(authState),

              const SizedBox(height: 20),

              // Balance Card
              _buildBalanceCard(walletState),

              if (walletState.error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(walletState.error!,
                      style: const TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 30),

              // Add Money Section
              _buildAddMoneySection(),

              const SizedBox(height: 30),

              // Transactions Section
              _buildTransactionsSection(walletState),
            ],
          ),
        ),
      ),
    );
  }

  // New method to show user info from auth provider
  Widget _buildUserInfoCard(authState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: authState.profilePic != null
                ? NetworkImage(authState.profilePic!)
                : null,
            child: authState.profilePic == null
                ? Text(authState.username?.substring(0, 1).toUpperCase() ?? 'U')
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.username ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authState.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (authState.mobileno != null)
                  Text(
                    authState.mobileno!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ID: ${authState.userId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(walletState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.indigo.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('My balance', style: TextStyle(fontSize: 16)),
          Text('₹${walletState.balance}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddMoneySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Money',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('₹', style: TextStyle(fontSize: 22)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6418C3), width: 2),
              ),
            ),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),

          // Quick Amount Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['200', '1000', '2000']
                .map((amount) => _buildAmountButton('₹ $amount',
                    () => _amountController.text = amount))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(child: _buildActionButton('Add Money', _startPayment,
                  const Color(0xFF6418C3))),
              const SizedBox(width: 10),
              Expanded(child: _buildActionButton('WithDraw', _showWithdrawDialog,
                  Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.indigo.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    final isLoading = ref.watch(walletProvider).isLoading || _isProcessing;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: isLoading
          ? const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text),
    );
  }

  Widget _buildTransactionsSection(walletState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),

        walletState.transactions.isEmpty
            ? const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('No transactions yet')))
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: walletState.transactions.length,
          itemBuilder: (context, index) => _buildTransactionItem(
              walletState.transactions[index]),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isCredit = transaction['type'] == 'credit';
    final timestamp = transaction['timestamp'] is int
        ? DateTime.fromMillisecondsSinceEpoch(transaction['timestamp'] as int)
        : transaction['timestamp'] is DateTime
        ? transaction['timestamp']
        : DateTime.now();

    final formattedDate = '${timestamp.day.toString().padLeft(2, '0')}/'
        '${timestamp.month.toString().padLeft(2, '0')}/'
        '${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction['description'] ?? 'Transaction'),
        subtitle: Text(formattedDate),
        trailing: Text(
          '${isCredit ? '+' : '-'} ₹${transaction['amount']}',
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}