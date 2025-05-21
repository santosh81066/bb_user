import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Screens/firebase.dart';

// Wallet state model
class WalletState {
  final double balance;
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final String? error;

  WalletState({
    required this.balance,
    required this.transactions,
    required this.isLoading,
    this.error,
  });

  WalletState copyWith({
    double? balance,
    List<Map<String, dynamic>>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Wallet notifier with debug logs
class WalletNotifier extends StateNotifier<WalletState> {
  final FirebaseRealtimeService _firebaseService;

  WalletNotifier(this._firebaseService)
      : super(WalletState(
          balance: 0.0,
          transactions: [],
          isLoading: false,
        ));

  // IMPROVED: Use single method to get all wallet data efficiently
  Future<void> loadWalletData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletData = await _firebaseService.getWalletSummary();

      print("Loaded wallet balance: ${walletData['balance']}");
      print("Loaded ${walletData['transactions'].length} transactions");

      state = state.copyWith(
        balance: walletData['balance'] as double,
        transactions:
            List<Map<String, dynamic>>.from(walletData['transactions']),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      print("Error in loadWalletData: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load wallet data: ${e.toString()}',
      );
    }
  }

  // IMPROVED: Better error handling and validation
  Future<bool> addToWallet(double amount) async {
    if (amount <= 0) {
      state = state.copyWith(error: 'Amount must be greater than zero');
      print('addToWallet error: Amount must be greater than zero');
      return false;
    }

    if (amount > 100000) {
      state = state.copyWith(
          error: 'Amount is too large. Maximum allowed is ₹100,000');
      print('addToWallet error: Amount too large');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    print('Starting addToWallet with amount: ₹$amount');

    try {
      // Try the transaction approach first
      bool success = await _firebaseService.addToWallet(amount);

      // If it fails, try the fallback approach
      if (!success) {
        print('Transaction approach failed, trying fallback');
        success = await _firebaseService.addToWalletFallback(amount);
      }

      print('addToWallet result: $success');

      if (success) {
        await loadWalletData();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to add money to wallet. Please try again.',
        );
        return false;
      }
    } catch (e) {
      print("Error in addToWallet: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please check your connection and try again.',
      );
      return false;
    }
  }

  // IMPROVED: Better validation and error messages
  Future<bool> makePayment(double amount, String description) async {
    if (amount <= 0) {
      state = state.copyWith(error: 'Amount must be greater than zero');
      return false;
    }

    // Validate description
    if (description.trim().isEmpty) {
      state = state.copyWith(error: 'Payment description is required');
      return false;
    }

    // Check balance before making API call
    if (state.balance < amount) {
      state = state.copyWith(
          error: 'Insufficient balance. Current balance: ₹${state.balance}');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success =
          await _firebaseService.deductFromWallet(amount, description.trim());

      if (success) {
        // Reload data from database to ensure consistency
        await loadWalletData();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Payment failed. Please try again.',
        );
        return false;
      }
    } catch (e) {
      print("Error in makePayment: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Payment failed due to network error. Please try again.',
      );
      return false;
    }
  }

  // ADDED: Method to clear errors
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // ADDED: Method to refresh wallet without loading state
  Future<void> refreshWallet() async {
    try {
      final walletData = await _firebaseService.getWalletSummary();

      state = state.copyWith(
        balance: walletData['balance'] as double,
        transactions:
            List<Map<String, dynamic>>.from(walletData['transactions']),
        error: null,
      );
    } catch (e) {
      print("Error in refreshWallet: $e");
      // Don't update error state for silent refresh
    }
  }
}

// Create providers
final firebaseRealtimeServiceProvider =
    Provider<FirebaseRealtimeService>((ref) {
  return FirebaseRealtimeService();
});

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final firebaseService = ref.watch(firebaseRealtimeServiceProvider);
  return WalletNotifier(firebaseService);
});
