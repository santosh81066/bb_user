import 'package:bb_user/Screens/walletscreen.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../Colors/coustcolors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hall_booking_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
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
  late int? bookingId;
  late Function(bool)? onPaymentSuccess;

  // Firebase Realtime Service
  final FirebaseRealtimeService _firebaseService = FirebaseRealtimeService();
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }

  Future<String?> _createRazorpayOrder() async {
    try {
      // Prepare order data
      final orderData = {
        'amount': (price ?? 1) * 100, // amount in paise
        'currency': 'INR',
        'receipt': 'bb_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {
          'hallId': hallId,
          'date': date,
          'slotFromTime': slotFromTime,
          'slotToTime': slotToTime,
          'bookingId': bookingId,
        }
      };

      // Send request to your backend to create Razorpay order
      final response = await http.post(
        Uri.parse('http://www.gocodedesigners.com/bbcreateorder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['id']; // Return the order ID
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error creating order: $e",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  Future<void> _loadWalletBalance() async {
    setState(() {
      _isLoadingWallet = true;
    });

    try {
      // First ensure Firebase is authenticated
      await _firebaseService.ensureAuthenticated();

      // Get wallet balance from Firebase
      double balance = await _firebaseService.getWalletBalance();

      setState(() {
        _walletBalance = balance;
        _isLoadingWallet = false;
      });
    } catch (e) {
      print('Error loading wallet balance: $e');
      setState(() {
        _walletBalance = 0.0;
        _isLoadingWallet = false;
      });

      Fluttertoast.showToast(
        msg: "Error loading wallet balance",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
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
      bookingId = args['bookingId']; // Add this to receive booking ID
      onPaymentSuccess = args['onPaymentSuccess'];

      // Set a more descriptive payment description
      if (hallName != null) {
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
    /* _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);*/
  }

  // Method to update booking status
  Future<void> _updateBookingStatus(bool isPaid) async {
    try {
      final hallBookingNotifier = ref.read(hallBookingProvider.notifier);

      if (isPaid) {
        // Update booking status to paid ('y')
        await hallBookingNotifier.postBooking(
          hallId: hallId ?? 0,
          bookingId: bookingId,
          date: date,
          slotFromTime: slotFromTime,
          slotToTime: slotToTime,
          isPaid: 'y', // 'y' means paid
        );

        print("Booking status updated to paid");
      } else {
        // If payment failed, ensure status remains as blocked ('b')
        await hallBookingNotifier.postBooking(
          hallId: hallId ?? 0,
          bookingId: bookingId,
          date: date,
          slotFromTime: slotFromTime,
          slotToTime: slotToTime,
          isPaid: 'b', // 'b' means blocked
        );

        print("Booking status updated to blocked");
      }
    } catch (e) {
      print("Error updating booking status: $e");
      Fluttertoast.showToast(
        msg: "Error updating booking status: $e",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  // Fix for the _handlePaymentSuccess method in PaymentPage class
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
      // First, update the booking status using the method in HallBookingNotifier
      final hallBookingNotifier = ref.read(hallBookingProvider.notifier);
      final success = await hallBookingNotifier.updateBookingWithPayment(
          hallId: hallId ?? 0,
          bookingId: bookingId,
          date: date,
          slotFromTime: slotFromTime,
          slotToTime: slotToTime,
          paymentMethod: 'razorpay',
          paymentId: response.paymentId ?? '',
          amount: (price ?? 0).toDouble(),
          isSuccess: true);

      if (success) {
        // Record the transaction to your backend
        final transaction = {
          'user_id': userId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'razorpay_signature': response.signature,
          'amt': price ?? 0,
          'payment_method': 'razorpay',
          'status': 'success'
        };

        final res = await http.post(
          Uri.parse('http://www.gocodedesigners.com/bbtransactionhistory'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(transaction),
        );

        if (res.statusCode == 201) {
          Fluttertoast.showToast(
            msg: "Payment successful and transaction recorded!",
            toastLength: Toast.LENGTH_SHORT,
          );

          if (onPaymentSuccess != null) onPaymentSuccess!(true);
          Navigator.pop(context);
        } else {
          // Even if transaction recording fails, the payment and booking were successful
          Fluttertoast.showToast(
            msg: "Payment successful but transaction recording failed",
            toastLength: Toast.LENGTH_LONG,
          );

          if (onPaymentSuccess != null) onPaymentSuccess!(true);
          Navigator.pop(context);
        }
      } else {
        Fluttertoast.showToast(
          msg: "Error updating booking status",
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error processing payment: $e",
        toastLength: Toast.LENGTH_LONG,
      );

      // Try to keep the booking as blocked even if there's an error
      try {
        await ref.read(hallBookingProvider.notifier).updateBookingPaymentStatus(
              bookingId: bookingId ?? 0,
              status: 'b', // Keep as blocked
            );
      } catch (_) {
        // Silently handle this error to avoid additional user confusion
      }
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
    print("Payment Error: ${response.error}");
    if (userId == null) {
      Fluttertoast.showToast(
          msg: "User ID not available for saving failed transaction");
      return;
    }

    try {
      final failedTransaction = {
        'user_id': userId,
        'razorpay_payment_id': '', // No payment ID in case of total failure
        'razorpay_order_id': '', // You can store attempt info if available
        'razorpay_signature': '',
        'amt': price ?? 1,
        'status': 'failed',
        'payment_method': 'razorpay'
      };

      final res = await http.post(
        Uri.parse('http://www.gocodedesigners.com/bbtransactionhistory'),
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

    // Update booking status to keep it as 'blocked'
    await _updateBookingStatus(false);

    if (onPaymentSuccess != null) {
      onPaymentSuccess!(false);
    }
  }

  // Modified _handleWalletPayment method for wallet payments
  void _handleWalletPayment() async {
    // Check if wallet has enough balance
    if (_walletBalance < (price ?? 0)) {
      showInsufficientBalanceDialog();
      return;
    }

    // Show confirmation dialog
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
              Navigator.pop(context); // Close dialog

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );

              try {
                // Deduct from wallet using Firebase
                final priceAmount = (price ?? 0).toDouble();
                final bookingDescription = hallName != null
                    ? "Booking payment for $hallName"
                    : "Banquet Booking Payment";

                final deductionResult = await _firebaseService.deductFromWallet(
                    priceAmount, bookingDescription);

                // Close loading dialog
                Navigator.pop(context);

                if (deductionResult) {
                  // Get updated balance after deduction
                  final newBalance = await _firebaseService.getWalletBalance();

                  // Generate a unique wallet payment ID
                  final walletPaymentId =
                      'wallet_${DateTime.now().millisecondsSinceEpoch}_${userId ?? 0}';

                  // Update booking payment status using the new method
                  final hallBookingNotifier =
                      ref.read(hallBookingProvider.notifier);
                  final success =
                      await hallBookingNotifier.updateBookingWithPayment(
                          hallId: hallId ?? 0,
                          bookingId: bookingId,
                          date: date,
                          slotFromTime: slotFromTime,
                          slotToTime: slotToTime,
                          paymentMethod: 'wallet',
                          paymentId: walletPaymentId,
                          amount: priceAmount,
                          isSuccess: true);

                  if (success) {
                    // Record the transaction to your backend as well
                    try {
                      final transaction = {
                        'user_id': userId,
                        'razorpay_payment_id': walletPaymentId,
                        'razorpay_order_id': '',
                        'razorpay_signature': '',
                        'amt': price ?? 0,
                        'payment_method': 'wallet',
                        'status': 'success'
                      };

                      final res = await http.post(
                        Uri.parse(
                            'http://www.gocodedesigners.com/bbtransactionhistory'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(transaction),
                      );

                      if (res.statusCode == 201) {
                        Fluttertoast.showToast(
                          msg: "Wallet Payment Successful!",
                          toastLength: Toast.LENGTH_LONG,
                        );

                        // Update wallet balance in state
                        setState(() {
                          _walletBalance = newBalance;
                        });

                        // Show success dialog with remaining balance
                        showSuccessDialog(newBalance);

                        // Call the callback function
                        if (onPaymentSuccess != null) {
                          onPaymentSuccess!(true);
                        }
                      } else {
                        // Even if transaction recording fails, the payment and booking were successful
                        Fluttertoast.showToast(
                            msg:
                                "Payment successful but transaction recording failed",
                            toastLength: Toast.LENGTH_LONG);

                        setState(() {
                          _walletBalance = newBalance;
                        });

                        // Show success dialog with remaining balance
                        showSuccessDialog(newBalance);

                        // Call the callback function
                        if (onPaymentSuccess != null) {
                          onPaymentSuccess!(true);
                        }
                      }
                    } catch (e) {
                      Fluttertoast.showToast(
                          msg: "Error saving transaction: $e");

                      // Update wallet balance in state even if there's an error
                      setState(() {
                        _walletBalance = newBalance;
                      });

                      // Show success dialog with remaining balance
                      showSuccessDialog(newBalance);

                      // Call the callback function
                      if (onPaymentSuccess != null) {
                        onPaymentSuccess!(true);
                      }
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg:
                          "Wallet payment successful but booking update failed",
                      toastLength: Toast.LENGTH_LONG,
                    );

                    // Still notify the parent component of success since money was deducted
                    if (onPaymentSuccess != null) {
                      onPaymentSuccess!(true);
                    }
                  }
                } else {
                  // Wallet deduction failed - could be insufficient balance or other error
                  Fluttertoast.showToast(
                    msg:
                        "Wallet payment failed. Please try again or use another payment method.",
                    toastLength: Toast.LENGTH_LONG,
                  );

                  // Refresh balance to get current value
                  _loadWalletBalance();
                }
              } catch (e) {
                // Close loading dialog if still showing
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                Fluttertoast.showToast(
                  msg: "Error processing wallet payment: $e",
                  toastLength: Toast.LENGTH_LONG,
                );

                // Refresh balance to get current value
                _loadWalletBalance();
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    /* final orderId = await _createRazorpayOrder();*/
    // Close loading dialog
    /* Navigator.pop(context);

    if (orderId == null) {
      Fluttertoast.showToast(
        msg: "Failed to create order. Please try again.",
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }*/
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

  /*void _handleWalletPayment() async {
    // Check if wallet has enough balance
    if (_walletBalance < (price ?? 0)) {
      showInsufficientBalanceDialog();
      return;
    }

    // Show confirmation dialog
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
              Navigator.pop(context); // Close dialog

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );

              try {
                // Deduct from wallet using Firebase
                final priceAmount = (price ?? 0).toDouble();
                final bookingDescription = hallName != null
                    ? "Booking payment for $hallName"
                    : "Banquet Booking Payment";

                final deductionResult = await _firebaseService.deductFromWallet(
                    priceAmount, bookingDescription);

                // Close loading dialog
                Navigator.pop(context);

                if (deductionResult) {
                  // Get updated balance after deduction
                  final newBalance = await _firebaseService.getWalletBalance();

                  // Record the transaction to your backend as well
                  try {
                    final transaction = {
                      'user_id': userId,
                      'razorpay_payment_id':
                      'wallet_${DateTime.now().millisecondsSinceEpoch}',
                      'razorpay_order_id': '',
                      'razorpay_signature': '',
                      'amt': price ?? 0,
                      'payment_method': 'wallet',
                      'status': 'success'
                    };

                    final res = await http.post(
                      Uri.parse(
                          'http://www.gocodedesigners.com/bbtransactionhistory'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(transaction),
                    );

                    if (res.statusCode == 201) {
                      // Update booking status to paid
                      await _updateBookingStatus(true);

                      Fluttertoast.showToast(
                        msg: "Wallet Payment Successful!",
                        toastLength: Toast.LENGTH_LONG,
                      );

                      // Update wallet balance in state
                      setState(() {
                        _walletBalance = newBalance;
                      });

                      // Show success dialog with remaining balance
                      showSuccessDialog(newBalance);

                      // Call the callback function
                      if (onPaymentSuccess != null) {
                        onPaymentSuccess!(true);
                      }
                    } else {
                      // Wallet deduction was successful, but backend recording failed
                      Fluttertoast.showToast(
                          msg:
                          "Payment successful but transaction recording failed",
                          toastLength: Toast.LENGTH_LONG);

                      setState(() {
                        _walletBalance = newBalance;
                      });

                      // Still update booking status as paid
                      await _updateBookingStatus(true);

                      // Still consider payment successful if wallet deduction worked
                      if (onPaymentSuccess != null) {
                        onPaymentSuccess!(true);
                      }
                    }
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Error saving transaction: $e");

                    // Update wallet balance in state even if there's an error
                    setState(() {
                      _walletBalance = newBalance;
                    });

                    // Still update booking status to paid
                    await _updateBookingStatus(true);

                    // Still consider payment successful if wallet deduction worked
                    if (onPaymentSuccess != null) {
                      onPaymentSuccess!(true);
                    }
                  }
                } else {
                  // Wallet deduction failed - could be insufficient balance or other error
                  Fluttertoast.showToast(
                    msg:
                    "Wallet payment failed. Please try again or use another payment method.",
                    toastLength: Toast.LENGTH_LONG,
                  );

                  // Refresh balance to get current value
                  _loadWalletBalance();
                }
              } catch (e) {
                // Close loading dialog if still showing
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                Fluttertoast.showToast(
                  msg: "Error processing wallet payment: $e",
                  toastLength: Toast.LENGTH_LONG,
                );

                // Refresh balance to get current value
                _loadWalletBalance();
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }*/

  void showInsufficientBalanceDialog() {
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
                    builder: (context) => const WalletScreen(),
                  )).then((_) {
                // Refresh wallet balance when returning from WalletScreen
                _loadWalletBalance();
              });
            },
            child: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void showSuccessDialog(double remainingBalance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text('₹${price ?? 0} has been deducted from your wallet.'),
            const SizedBox(height: 8),
            Text(
              'Remaining balance: ₹$remainingBalance',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
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
                    if (hallName != null) _buildDetailRow('Hall', hallName!),
                    _buildDetailRow('Date', date),
                    _buildDetailRow('Time', '$slotFromTime to $slotToTime'),
                    const Divider(height: 20),
                    const Text('Payment Status',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
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
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
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
                        const Text('Total Amount',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '₹ ${price ?? 0}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My balance', style: TextStyle(fontSize: 16)),
                  _isLoadingWallet
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))
                      : Text('₹ $_walletBalance',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Payment Description',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedPaymentMethod == 0) {
                    _handleWalletPayment();
                  } else {
                    _openRazorpayPayment();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6418C3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
