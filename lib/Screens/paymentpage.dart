import 'package:bb_user/Screens/walletscreen.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../Colors/coustcolors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Providers/firebase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hall_booking_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  int _selectedPaymentMethod = 1;
  late Razorpay _razorpay;
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Booking details
  late int? hallId, price, bookingId, userId;
  late String date, slotFromTime, slotToTime, hallName;
  late Function(bool)? onPaymentSuccess;

  final _firebaseService = FirebaseRealtimeService();
  double _walletBalance = 0.0;
  bool _isLoadingWallet = true;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadUserId();
    _loadWalletBalance();
    _descriptionController.text = "Banquet Booking Payment";
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getInt('user_id'));
  }

  Future<void> _loadWalletBalance() async {
    setState(() => _isLoadingWallet = true);
    try {
      await _firebaseService.ensureAuthenticated();
      final balance = await _firebaseService.getWalletBalance();
      setState(() {
        _walletBalance = balance;
        _isLoadingWallet = false;
      });
    } catch (e) {
      setState(() {
        _walletBalance = 0.0;
        _isLoadingWallet = false;
      });
      Fluttertoast.showToast(msg: "Error loading wallet balance");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      hallId = args['hallId'];
      date = args['date'] ?? '';
      slotFromTime = args['slotFromTime'] ?? '';
      slotToTime = args['slotToTime'] ?? '';
      hallName = args['hallName'] ?? '';
      price = args['price'] ?? 0;
      bookingId = args['bookingId'];
      onPaymentSuccess = args['onPaymentSuccess'];

      if (hallName.isNotEmpty) {
        _descriptionController.text =
            "Booking payment for $hallName on $date from $slotFromTime to $slotToTime";
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _mobileController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Fluttertoast.showToast(msg: "Payment Successful: ${response.paymentId}");

    if (userId == null) {
      Fluttertoast.showToast(msg: "User ID not available");
      return;
    }

    try {
      print('Processing Razorpay payment success...');
      final hallBookingNotifier = ref.read(hallBookingProvider.notifier);

      // Update booking with payment details
      final success = await hallBookingNotifier.updateBookingWithPayment(
        hallId: hallId ?? 0,
        bookingId: bookingId,
        date: date,
        slotFromTime: slotFromTime,
        slotToTime: slotToTime,
        paymentMethod: 'razorpay',
        paymentId: response.paymentId ?? '',
        amount: (price ?? 0).toDouble(),
        isSuccess: true,
      );

      if (success) {
        // Record transaction with success status
        await _recordTransaction({
          'user_id': userId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'razorpay_signature': response.signature,
          'amt': price ?? 0,
          'payment_method': 'razorpay',
          'status': 'success',
          'booking_id': bookingId,
          'is_paid': true,
        });

        Fluttertoast.showToast(msg: "Payment successful! Booking confirmed.");
        onPaymentSuccess?.call(true);
        Navigator.pop(context);
      } else {
        // Payment processing failed
        await _recordTransaction({
          'user_id': userId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'razorpay_signature': response.signature,
          'amt': price ?? 0,
          'payment_method': 'razorpay',
          'status': 'failed',
          'booking_id': bookingId,
          'is_paid': false,
        });

        Fluttertoast.showToast(
            msg:
                "Payment received but booking update failed. Please contact support.");
      }
    } catch (e) {
      print('Error processing Razorpay payment: $e');

      // Record failed transaction
      await _recordTransaction({
        'user_id': userId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
        'amt': price ?? 0,
        'payment_method': 'razorpay',
        'status': 'error',
        'booking_id': bookingId,
        'is_paid': false,
        'error_message': e.toString(),
      });

      Fluttertoast.showToast(msg: "Error processing payment: $e");

      // Try to update booking status to failed
      try {
        if (bookingId != null) {
          await ref
              .read(hallBookingProvider.notifier)
              .updateBookingPaymentStatus(
                bookingId: bookingId!,
                status: 'n', // failed
              );
        }
      } catch (fallbackError) {
        print('Failed to update booking status to failed: $fallbackError');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    print('Razorpay payment failed: ${response.message}');
    Fluttertoast.showToast(msg: "Payment Failed: ${response.message}");

    if (userId != null) {
      // Record failed transaction
      await _recordTransaction({
        'user_id': userId,
        'razorpay_payment_id': '',
        'razorpay_order_id': '',
        'razorpay_signature': '',
        'amt': price ?? 0,
        'status': 'failed',
        'payment_method': 'razorpay',
        'booking_id': bookingId,
        'is_paid': false,
        'error_message': response.message,
      });

      // Update booking status to failed if we have a booking ID
      if (bookingId != null) {
        try {
          await ref
              .read(hallBookingProvider.notifier)
              .updateBookingPaymentStatus(
                bookingId: bookingId!,
                status: 'n', // failed
              );
          print('Updated booking status to failed');
        } catch (e) {
          print('Failed to update booking status: $e');
        }
      }
    }

    onPaymentSuccess?.call(false);
  }

  Future<void> _recordTransaction(Map<String, dynamic> transaction) async {
    try {
      print('Recording transaction: ${transaction['status']}');

      final response = await http.post(
        Uri.parse('http://www.gocodedesigners.com/bbtransactionhistory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Transaction recorded successfully');
      } else {
        print('Failed to record transaction: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print("Error recording transaction: $e");
    }
  }

  void _handleWalletPayment() async {
    if (_walletBalance < (price ?? 0)) {
      _showInsufficientBalanceDialog();
      return;
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Pay ₹${price ?? 0} from your wallet balance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processWalletPayment();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWalletPayment() async {
    _showLoadingDialog();
    print('Processing wallet payment...');

    try {
      final priceAmount = (price ?? 0).toDouble();
      final bookingDescription = hallName.isNotEmpty
          ? "Booking payment for $hallName"
          : "Banquet Booking Payment";

      // First, deduct from wallet
      final deductionResult = await _firebaseService.deductFromWallet(
          priceAmount, bookingDescription);

      Navigator.pop(context); // Close loading dialog

      if (deductionResult) {
        print('Wallet deduction successful, updating booking...');

        final newBalance = await _firebaseService.getWalletBalance();
        final walletPaymentId =
            'wallet_${DateTime.now().millisecondsSinceEpoch}_${userId ?? 0}';

        // Update booking with payment details
        final success = await ref
            .read(hallBookingProvider.notifier)
            .updateBookingWithPayment(
              hallId: hallId ?? 0,
              bookingId: bookingId,
              date: date,
              slotFromTime: slotFromTime,
              slotToTime: slotToTime,
              paymentMethod: 'wallet',
              paymentId: walletPaymentId,
              amount: priceAmount,
              isSuccess: true,
            );

        if (success) {
          print('Booking updated successfully after wallet payment');

          // Record successful transaction
          await _recordTransaction({
            'user_id': userId,
            'razorpay_payment_id': walletPaymentId,
            'razorpay_order_id': '',
            'razorpay_signature': '',
            'amt': price ?? 0,
            'payment_method': 'wallet',
            'status': 'success',
            'booking_id': bookingId,
            'is_paid': true,
          });

          setState(() => _walletBalance = newBalance);
          _showSuccessDialog(newBalance);
          onPaymentSuccess?.call(true);
        } else {
          print('Booking update failed after wallet payment');

          // Booking update failed, record failed transaction
          await _recordTransaction({
            'user_id': userId,
            'razorpay_payment_id': walletPaymentId,
            'razorpay_order_id': '',
            'razorpay_signature': '',
            'amt': price ?? 0,
            'payment_method': 'wallet',
            'status': 'failed',
            'booking_id': bookingId,
            'is_paid': false,
            'error_message': 'Booking update failed after wallet deduction',
          });

          Fluttertoast.showToast(
              msg:
                  "Wallet payment deducted but booking update failed. Please contact support.");

          // Try to refund the wallet (if your system supports it)
          // await _firebaseService.addToWallet(priceAmount, "Refund for failed booking");
        }
      } else {
        print('Wallet deduction failed');

        // Record failed transaction
        await _recordTransaction({
          'user_id': userId,
          'razorpay_payment_id': '',
          'razorpay_order_id': '',
          'razorpay_signature': '',
          'amt': price ?? 0,
          'payment_method': 'wallet',
          'status': 'failed',
          'booking_id': bookingId,
          'is_paid': false,
          'error_message': 'Wallet deduction failed',
        });

        // Update booking status to failed if we have a booking ID
        if (bookingId != null) {
          try {
            await ref
                .read(hallBookingProvider.notifier)
                .updateBookingPaymentStatus(
                  bookingId: bookingId!,
                  status: 'n', // failed
                );
          } catch (e) {
            print('Failed to update booking status: $e');
          }
        }

        Fluttertoast.showToast(
            msg:
                "Wallet payment failed. Please try again or use another payment method.");
        _loadWalletBalance();
      }
    } catch (e) {
      print('Error processing wallet payment: $e');
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Record error transaction
      await _recordTransaction({
        'user_id': userId,
        'razorpay_payment_id': '',
        'razorpay_order_id': '',
        'razorpay_signature': '',
        'amt': price ?? 0,
        'payment_method': 'wallet',
        'status': 'error',
        'booking_id': bookingId,
        'is_paid': false,
        'error_message': e.toString(),
      });

      Fluttertoast.showToast(msg: "Error processing wallet payment: $e");
      _loadWalletBalance();
    }
  }

  void _openRazorpayPayment() {
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final description = _descriptionController.text.trim();

    if (mobile.isEmpty || email.isEmpty || description.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please enter mobile, email, and description");
      return;
    }

    _showLoadingDialog();
    final options = {
      'key': 'rzp_live_4mzpwZrJggHKRm',
      'amount': (price ?? 1) * 100,
      'currency': 'INR',
      'name': 'BANQUETBOOKZ',
      'description': description,
      'prefill': {'contact': mobile, 'email': email},
      'notes': {
        'hallId': hallId,
        'date': date,
        'slotFromTime': slotFromTime,
        'slotToTime': slotToTime,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Your wallet balance (₹$_walletBalance) is less than the required amount (₹${price ?? 0}).'),
            const SizedBox(height: 16),
            const Text('Would you like to add money to your wallet?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WalletScreen()))
                  .then((_) => _loadWalletBalance());
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(double remainingBalance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text('₹${price ?? 0} has been deducted from your wallet.'),
            const SizedBox(height: 8),
            Text('Remaining balance: ₹$remainingBalance',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFF6418C3),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Payment', style: TextStyle(color: Colors.white)),
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingDetailsCard(),
            const SizedBox(height: 20),
            _buildPaymentDetailsCard(),
            const SizedBox(height: 20),
            _buildWalletBalanceCard(),
            const SizedBox(height: 20),
            _buildFormFields(),
            const SizedBox(height: 20),
            _buildPaymentMethodSection(),
            const SizedBox(height: 30),
            _buildPayButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Details',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6418C3))),
            const SizedBox(height: 10),
            if (hallName.isNotEmpty) _buildDetailRow('Hall', hallName),
            _buildDetailRow('Date', date),
            _buildDetailRow('Time', '$slotFromTime to $slotToTime'),
            const Divider(height: 20),
            const Text('Payment Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending_actions,
                      size: 16, color: Colors.amber[800]),
                  const SizedBox(width: 6),
                  Text('Pending Payment',
                      style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hall Booking Fee'),
                Text('₹ ${price ?? 0}')
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹ ${price ?? 0}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: CoustColors.colrStrock1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('My balance', style: TextStyle(fontSize: 16)),
          _isLoadingWallet
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('₹ $_walletBalance',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(_emailController, 'Email Address', Icons.email,
            TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildTextField(_mobileController, 'Mobile Number', Icons.phone,
            TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField(_descriptionController, 'Payment Description',
            Icons.description, TextInputType.text),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildPaymentMethodOption(
          isSelected: _selectedPaymentMethod == 0,
          icon: Icons.account_balance_wallet,
          title: 'Pay from Wallet',
          subtitle: 'Available Balance: ₹ $_walletBalance',
          onTap: () => setState(() => _selectedPaymentMethod = 0),
        ),
        const SizedBox(height: 10),
        _buildPaymentMethodOption(
          isSelected: _selectedPaymentMethod == 1,
          icon: Icons.payment,
          title: 'Pay from Razorpay',
          subtitle: 'Credit/Debit Card, UPI, Net Banking & more',
          onTap: () => setState(() => _selectedPaymentMethod = 1),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _selectedPaymentMethod == 0
            ? _handleWalletPayment()
            : _openRazorpayPayment(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6418C3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6418C3) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6418C3).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected ? const Color(0xFF6418C3) : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF6418C3)),
          ],
        ),
      ),
    );
  }
}
