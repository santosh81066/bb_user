import 'package:bb_user/Screens/walletscreen.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../Colors/coustcolors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedPaymentMethod = 1; // 0 for wallet, 1 for Razorpay
  late Razorpay _razorpay;
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late int? hallId;
  late String date;
  late String slotFromTime;
  late String slotToTime;
  late String? hallName;
  late int? price;
  int? userId;
  late Function(bool)? onPaymentSuccess;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadUserId();
    _descriptionController.text = "Banquet Booking Payment";
  }
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      hallId = args['hallId'];
      date = args['date'] ?? '';
      slotFromTime = args['slotFromTime'] ?? '';
      slotToTime = args['slotToTime'] ?? '';
      hallName = args['hallName'];
      price = args['price'] ?? 0;
      onPaymentSuccess = args['onPaymentSuccess'];

      // Set a more descriptive payment description
      if (hallName != null) {
        _descriptionController.text = "Booking payment for $hallName on $date from $slotFromTime to $slotToTime";
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
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Fluttertoast.showToast(
      msg: "Payment Successful: ${response.paymentId}",
      toastLength: Toast.LENGTH_SHORT,
    );

    if (userId == null) {
      Fluttertoast.showToast(msg: "User ID not available");
      return;
    }

    try {
      final transaction = {
        'user_id': userId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
        'amt': price ?? 1,
      };

      final res = await http.post(
        Uri.parse('https://www.gocodedesigners.com/bbtransactionhistory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction),
      );

      if (res.statusCode == 201) {
        if (onPaymentSuccess != null) onPaymentSuccess!(true);
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: "Transaction save failed: ${res.body}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving transaction: $e");
    }
  }


  void _handlePaymentError(PaymentFailureResponse response) async {
    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      toastLength: Toast.LENGTH_SHORT,
    );

    print("Payment Failed");
    print("Code: ${response.code}");
    print("Message: ${response.message}");
    print ("Payment Error: ${response.error}");
    if (userId == null) {
      Fluttertoast.showToast(msg: "User ID not available for saving failed transaction");
      return;
    }

    try {
      final failedTransaction = {
        'user_id': userId,
        'razorpay_payment_id': '', // No payment ID in case of total failure
        'razorpay_order_id': '',   // You can store attempt info if available
        'razorpay_signature': '',
        'amt': price ?? 1,
        'status': 'failed'
      };

      final res = await http.post(
        Uri.parse('https://www.gocodedesigners.com/bbtransactionhistory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(failedTransaction),
      );

      if (res.statusCode == 201) {
        print("Failed transaction recorded");
      } else {
        print("Failed to record failed transaction: ${res.body}");
      }
    } catch (e) {
      print("Error sending failed transaction: $e");
    }

    if (onPaymentSuccess != null) {
      onPaymentSuccess!(false);
    }

  }


  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External Wallet Selected: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }



  void _openRazorpayPayment() {
    String mobile = _mobileController.text.trim();
    String email = _emailController.text.trim();
    String description = _descriptionController.text.trim();

    if (mobile.isEmpty || email.isEmpty || description.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter mobile, email, and description",
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    int amountInPaise = (price ?? 1) * 100;

    var options = {
      'key': 'rzp_live_4mzpwZrJggHKRm', // Replace with your Razorpay key
      'amount': amountInPaise,
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
      debugPrint('Error: $e');
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }
  void _handleWalletPayment() {
    // Implement wallet payment logic
    // Here you would check if the wallet has enough balance

    // For demonstration, let's assume wallet payment is successful
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
            onPressed: () {
              Navigator.pop(context); // Close dialog

              // Simulate successful payment
              Fluttertoast.showToast(
                msg: "Wallet Payment Successful!",
                toastLength: Toast.LENGTH_SHORT,
              );

              // Call the callback function
              if (onPaymentSuccess != null) {
                onPaymentSuccess!(true);
              }

              // Return to previous screen
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:PreferredSize(
        preferredSize: const Size.fromHeight(80), // height of AppBar
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFF6418C3),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              color: Colors.white,
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
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Booking Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6418C3))),
                    const SizedBox(height: 10),

                    if (hallName != null)
                      _buildDetailRow('Hall', hallName!),

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
                          Icon(Icons.pending_actions, size: 16, color: Colors.amber[800]),
                          const SizedBox(width: 6),
                          Text('Pending Payment',
                              style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hall Booking Fee'),
                        Text('₹ ${price ?? 0}'),
                      ],
                    ),
                    const Divider(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '₹ ${price ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: CoustColors.colrStrock1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My balance', style: TextStyle(fontSize: 16)),
                  Text('200', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Payment Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPaymentMethodOption(
              isSelected: _selectedPaymentMethod == 0,
              icon: Icons.account_balance_wallet,
              title: 'Pay from Wallet',
              subtitle: 'Available Balance: ₹ 200',
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
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedPaymentMethod == 0) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
                  } else {
                    _openRazorpayPayment();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6418C3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Pay Now'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                color: isSelected ? const Color(0xFF6418C3).withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? const Color(0xFF6418C3) : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6418C3)),
          ],
        ),
      ),
    );
  }
}
