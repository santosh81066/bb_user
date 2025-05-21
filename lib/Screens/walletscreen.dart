import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Providers/wallet.dart';
import '../Screens/firebase.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final TextEditingController _amountController = TextEditingController(text: '10');
  late Razorpay _razorpay;
  final _firebaseService = FirebaseRealtimeService();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _setupRazorpay();

    // Load wallet data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  // Moved to separate method for easier calling
  Future<void> _loadWalletData() async {
    await ref.read(walletProvider.notifier).loadWalletData();
  }

  void _setupRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_isProcessingPayment) return; // Prevent double processing

    setState(() {
      _isProcessingPayment = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful, updating wallet...')),
    );

    final amount = double.tryParse(_amountController.text);
    if (amount != null) {
      try {
        // Add amount to wallet using the wallet provider
        final success = await ref.read(walletProvider.notifier).addToWallet(amount);

        // Force a reload of wallet data
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadWalletData();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('₹$amount added to wallet! Payment ID: ${response.paymentId}')),
          );
        } else {
          final errorMsg = ref.read(walletProvider).error ?? 'Failed to add money';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating wallet: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  void _startRazorpayPayment() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    var options = {
      'key': 'rzp_live_4mzpwZrJggHKRm', // 🔑 replace with your Razorpay key
      'amount': (amount * 100).toInt(), // amount in paise
      'name': 'Wallet Top-up',
      'description': 'Add Money to Wallet',
      'prefill': {
        'contact': _firebaseService.currentUser?.phoneNumber ?? '9123456789',
        'email': _firebaseService.currentUser?.email ?? 'test@example.com'
      },
      'theme': {
        'color': '#6418C3',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open payment: ${e.toString()}')),
      );
    }
  }

  // Function to make payment from wallet
  Future<void> _makePaymentFromWallet() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final walletState = ref.read(walletProvider);

    // Check if balance is sufficient
    if (walletState.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance in wallet')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Do you want to pay ₹$amount from your wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing payment...')),
              );

              // Process payment using wallet provider
              final success = await ref.read(walletProvider.notifier)
                  .makePayment(amount, 'Payment for booking');

              // Force a reload of wallet data
              await Future.delayed(const Duration(milliseconds: 500));
              await _loadWalletData();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment of ₹$amount successful')),
                );
              } else {
                // Error message is handled in the wallet provider
                final errorMsg = ref.read(walletProvider).error ?? 'Payment failed';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMsg)),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Refresh wallet data
  Future<void> _refreshWalletData() async {
    await _loadWalletData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet refreshed')),
    );
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    // Get wallet state from provider
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6418C3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
        title: const Text('Wallet', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: walletState.isLoading ? null : _refreshWalletData,
          ),
        ],
      ),
      body: walletState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshWalletData,
        child: Column(
          children: [
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
            Container(
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
                  Text('₹${walletState.balance}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Error message if there is one
            if (walletState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  walletState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Add Money', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
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
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountButton('₹ 200', () => _amountController.text = '200'),
                  _amountButton('₹ 1000', () => _amountController.text = '1000'),
                  _amountButton('₹ 2000', () => _amountController.text = '2000'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: walletState.isLoading || _isProcessingPayment ? null : _startRazorpayPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6418C3),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: walletState.isLoading || _isProcessingPayment
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Add Money'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: walletState.isLoading || _isProcessingPayment ? null : _makePaymentFromWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: walletState.isLoading || _isProcessingPayment
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Pay from Wallet'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: walletState.transactions.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: walletState.transactions.length,
                itemBuilder: (context, index) {
                  final transaction = walletState.transactions[index];
                  final isCredit = transaction['type'] == 'credit';

                  // Handle different timestamp formats
                  final timestamp = transaction['timestamp'] is int
                      ? DateTime.fromMillisecondsSinceEpoch(
                      transaction['timestamp'] as int)
                      : transaction['timestamp'] is DateTime
                      ? transaction['timestamp']
                      : DateTime.now();

                  final formattedDate =
                      '${timestamp.day.toString().padLeft(2, '0')}/'
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
                          color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountButton(String text, VoidCallback onTap) {
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
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}