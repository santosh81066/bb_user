import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Initialize anonymous authentication
  Future<bool> ensureAuthenticated() async {
    try {
      // Check if already authenticated
      if (_auth.currentUser != null) {
        print('Already authenticated: ${_auth.currentUser!.uid}');
        return true;
      }

      // Sign in anonymously
      print('Signing in anonymously...');
      UserCredential userCredential = await _auth.signInAnonymously();
      print('Signed in anonymously: ${userCredential.user!.uid}');
      return true;
    } catch (e) {
      print('Error ensuring authentication: $e');
      return false;
    }
  }

  // Get wallet balance - with auth check
  Future<double> getWalletBalance() async {
    try {
      // Ensure user is authenticated before proceeding
      if (!await ensureAuthenticated()) {
        print('Failed to authenticate for getWalletBalance');
        return 0.0;
      }

      // Force a refresh from the server, not just cache
      DataSnapshot snapshot =
          await _database.ref('users/${currentUser!.uid}/walletBalance').get();

      if (snapshot.exists) {
        // Convert to double (handling both int and double cases from database)
        var value = snapshot.value;
        if (value is int) {
          return value.toDouble();
        } else if (value is double) {
          return value;
        }
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }

  // CRITICAL FIX: Use atomic transaction with authentication check
  Future<bool> addToWallet(double amount) async {
    try {
      // First, ensure authentication
      if (!await ensureAuthenticated()) {
        print('Failed to authenticate for addToWallet');
        return false;
      }

      print('Starting transaction for user: ${currentUser!.uid}');
      DatabaseReference userRef = _database.ref('users/${currentUser!.uid}');

      // Use transaction to ensure atomicity
      TransactionResult result = await userRef.runTransaction((Object? post) {
        // Initialize with simple default structure
        Map<String, dynamic> userData;

        if (post == null) {
          // If node doesn't exist yet, create a simple structure
          userData = {'walletBalance': amount, 'transactions': {}};
        } else {
          try {
            userData = Map<String, dynamic>.from(post as Map);

            // Get current balance with safer type handling
            double currentBalance = 0.0;
            if (userData['walletBalance'] != null) {
              var balance = userData['walletBalance'];
              currentBalance = balance is int
                  ? balance.toDouble()
                  : balance is double
                      ? balance
                      : 0.0;
            }

            // Update balance
            userData['walletBalance'] = currentBalance + amount;

            // Ensure transactions exists
            if (userData['transactions'] == null) {
              userData['transactions'] = {};
            }
          } catch (e) {
            // If data conversion fails, reset with new structure
            print('Data conversion error: $e');
            userData = {'walletBalance': amount, 'transactions': {}};
          }
        }

        // Create transaction ID
        String transactionId = DateTime.now().millisecondsSinceEpoch.toString();

        // Add transaction record
        userData['transactions'][transactionId] = {
          'amount': amount,
          'type': 'credit',
          'description': 'Added to wallet',
          'timestamp': ServerValue.timestamp,
        };

        return Transaction.success(userData);
      });

      print(
          'Transaction result - committed: ${result.committed}, snapshot exists: ${result.snapshot.exists}');
      return result.committed;
    } catch (e) {
      print('Detailed error adding to wallet: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
      return false;
    }
  }

  Future<bool> addToWalletFallback(double amount) async {
    try {
      // Ensure authentication
      if (!await ensureAuthenticated()) {
        print('Failed to authenticate for addToWalletFallback');
        return false;
      }

      // First get current balance
      DataSnapshot snapshot =
          await _database.ref('users/${currentUser!.uid}/walletBalance').get();

      double currentBalance = 0.0;
      if (snapshot.exists && snapshot.value != null) {
        var value = snapshot.value;
        currentBalance = value is int
            ? value.toDouble()
            : value is double
                ? value
                : 0.0;
      }

      // Calculate new balance
      double newBalance = currentBalance + amount;

      // Create transaction record
      String transactionId = _database.ref().push().key!;
      Map<String, dynamic> transactionData = {
        'amount': amount,
        'type': 'credit',
        'description': 'Added to wallet',
        'timestamp': ServerValue.timestamp,
      };

      // Create update map
      Map<String, dynamic> updates = {};
      updates['users/${currentUser!.uid}/walletBalance'] = newBalance;
      updates['users/${currentUser!.uid}/transactions/$transactionId'] =
          transactionData;

      // Apply updates
      await _database.ref().update(updates);
      return true;
    } catch (e) {
      print('Error in addToWalletFallback: $e');
      return false;
    }
  }

  // CRITICAL FIX: Use atomic transaction with authentication check
  Future<bool> deductFromWallet(double amount, String description) async {
    try {
      // Ensure authentication
      if (!await ensureAuthenticated()) {
        print('Failed to authenticate for deductFromWallet');
        return false;
      }

      DatabaseReference userRef = _database.ref('users/${currentUser!.uid}');

      // Use transaction to ensure atomicity and prevent race conditions
      TransactionResult result = await userRef.runTransaction((Object? post) {
        Map<String, dynamic> userData = post != null
            ? Map<String, dynamic>.from(post as Map)
            : {'walletBalance': 0.0, 'transactions': {}};

        // Get current balance
        double currentBalance = 0.0;
        if (userData['walletBalance'] != null) {
          var balance = userData['walletBalance'];
          currentBalance =
              balance is int ? balance.toDouble() : (balance as double? ?? 0.0);
        }

        // Check if balance is sufficient
        if (currentBalance < amount) {
          // Abort transaction if insufficient balance
          return Transaction.abort();
        }

        // Calculate new balance
        double newBalance = currentBalance - amount;

        // Create transaction ID
        String transactionId = _database.ref().push().key!;

        // Update user data
        userData['walletBalance'] = newBalance;

        // Ensure transactions map exists
        if (userData['transactions'] == null) {
          userData['transactions'] = {};
        }

        // Add transaction record
        userData['transactions'][transactionId] = {
          'amount': amount,
          'type': 'debit',
          'description': description,
          'timestamp': ServerValue.timestamp,
        };

        return Transaction.success(userData);
      });

      return result.committed;
    } catch (e) {
      print('Error deducting from wallet: $e');
      return false;
    }
  }

  // With auth check
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      // Ensure authentication
      if (!await ensureAuthenticated()) {
        print('Failed to authenticate for getTransactionHistory');
        return [];
      }

      DataSnapshot snapshot = await _database
          .ref('users/${currentUser!.uid}/transactions')
          .orderByChild('timestamp')
          .get();

      List<Map<String, dynamic>> transactions = <Map<String, dynamic>>[];

      if (snapshot.exists && snapshot.value != null) {
        if (snapshot.value is Map) {
          Map<dynamic, dynamic> transactionsMap =
              snapshot.value as Map<dynamic, dynamic>;

          transactionsMap.forEach((key, value) {
            if (value is Map &&
                value['amount'] != null &&
                value['type'] != null) {
              try {
                Map<String, dynamic> transaction = <String, dynamic>{
                  'id': key.toString(),
                  'amount': value['amount'] is int
                      ? (value['amount'] as int).toDouble()
                      : (value['amount'] as double? ?? 0.0),
                  'type': value['type'].toString(),
                  'description':
                      value['description']?.toString() ?? 'Transaction',
                  'timestamp': value['timestamp'] ??
                      DateTime.now().millisecondsSinceEpoch,
                };
                transactions.add(transaction);
              } catch (e) {
                print('Error parsing transaction $key: $e');
                // Skip malformed transactions
              }
            }
          });

          // Sort by timestamp (descending - most recent first)
          transactions.sort((a, b) {
            int timestampA = a['timestamp'] is int ? a['timestamp'] : 0;
            int timestampB = b['timestamp'] is int ? b['timestamp'] : 0;
            return timestampB.compareTo(timestampA);
          });
        }
      }

      return transactions;
    } catch (e) {
      print('Error getting transaction history: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // With auth check
  Future<Map<String, dynamic>> getWalletSummary() async {
    try {
      // Ensure authentication
      if (!await ensureAuthenticated()) {
        print('Failed to authenticate for getWalletSummary');
        return {'balance': 0.0, 'transactions': <Map<String, dynamic>>[]};
      }

      DataSnapshot snapshot =
          await _database.ref('users/${currentUser!.uid}').get();

      double balance = 0.0;
      List<Map<String, dynamic>> transactions = <Map<String, dynamic>>[];

      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> userData =
            Map<String, dynamic>.from(snapshot.value as Map);

        // Get balance
        if (userData['walletBalance'] != null) {
          var balanceValue = userData['walletBalance'];
          balance = balanceValue is int
              ? balanceValue.toDouble()
              : (balanceValue as double? ?? 0.0);
        }

        // Get transactions
        if (userData['transactions'] != null &&
            userData['transactions'] is Map) {
          Map<dynamic, dynamic> transactionsMap =
              userData['transactions'] as Map<dynamic, dynamic>;

          transactionsMap.forEach((key, value) {
            if (value is Map &&
                value['amount'] != null &&
                value['type'] != null) {
              try {
                Map<String, dynamic> transaction = <String, dynamic>{
                  'id': key.toString(),
                  'amount': value['amount'] is int
                      ? (value['amount'] as int).toDouble()
                      : (value['amount'] as double? ?? 0.0),
                  'type': value['type'].toString(),
                  'description':
                      value['description']?.toString() ?? 'Transaction',
                  'timestamp': value['timestamp'] ??
                      DateTime.now().millisecondsSinceEpoch,
                };
                transactions.add(transaction);
              } catch (e) {
                print('Error parsing transaction $key: $e');
              }
            }
          });

          // Sort by timestamp (descending)
          transactions.sort((a, b) {
            int timestampA = a['timestamp'] is int ? a['timestamp'] : 0;
            int timestampB = b['timestamp'] is int ? b['timestamp'] : 0;
            return timestampB.compareTo(timestampA);
          });
        }
      }

      return <String, dynamic>{
        'balance': balance,
        'transactions': transactions,
      };
    } catch (e) {
      print('Error getting wallet summary: $e');
      return <String, dynamic>{
        'balance': 0.0,
        'transactions': <Map<String, dynamic>>[]
      };
    }
  }
}
