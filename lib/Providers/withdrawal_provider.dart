
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/withdrawal_request.dart';
import '../models/withdrawal_response.dart';

// Configuration
class ApiConfig {
  static const String baseUrl = 'http://www.gocodedesigners.com'; // Replace with your actual URL
  static const String withdrawalEndpoint = '/bbwithdrawrequest';
  static const String accessToken = 'test_token'; // Replace with actual token management
}

// Withdrawal Service
class WithdrawalService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _endpoint = ApiConfig.withdrawalEndpoint;

  Future<WithdrawalResponse> submitWithdrawal(WithdrawalRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_endpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': ApiConfig.accessToken,
        },
        body: json.encode(request.toJson()),
      );

      final responseData = json.decode(response.body);

      return WithdrawalResponse(
        statusCode: response.statusCode,
        success: responseData['success'] ?? false,
        message: responseData['message'],
        data: responseData['data'],
      );
    } catch (e) {
      return WithdrawalResponse(
        statusCode: 500,
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    try {
      final url = Uri.parse('$_baseUrl$_endpoint?userwithdraw=true');

      final response = await http.get(
        url,
        headers: {
          'Authorization': ApiConfig.accessToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

// Withdrawal Provider
final withdrawalServiceProvider = Provider<WithdrawalService>((ref) {
  return WithdrawalService();
});

// Withdrawal State
class WithdrawalState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const WithdrawalState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  WithdrawalState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return WithdrawalState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Withdrawal Controller
class WithdrawalController extends StateNotifier<WithdrawalState> {
  final WithdrawalService _withdrawalService;

  WithdrawalController(this._withdrawalService) : super(const WithdrawalState());

  Future<void> submitWithdrawal({
    required double amount,
    required String method,
    required String details,
    required int userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      // Parse the details based on method
      String? upi;
      String? accountNumber;
      String? ifsc;
      String accountHolder = 'User'; // Default, you might want to get this from user profile

      if (method == 'UPI') {
        upi = details;
      } else {
        // Bank transfer - parse the details string
        final parts = details.split(' - ');
        if (parts.length >= 3) {
          accountHolder = parts[0];
          accountNumber = parts[1];
          ifsc = parts[2];
        }
      }

      final request = WithdrawalRequest(
        accountHolder: accountHolder,
        amount: amount,
        ifsc: ifsc,
        account: accountNumber,
        upi: upi,
        userId: userId,
        status: 'p', // pending
      );

      final response = await _withdrawalService.submitWithdrawal(request);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message ?? 'Withdrawal request submitted successfully!',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to submit withdrawal request',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Provider for Withdrawal Controller
final withdrawalControllerProvider = StateNotifierProvider<WithdrawalController, WithdrawalState>((ref) {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  return WithdrawalController(withdrawalService);
});

// User Transactions Provider
final userTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  return await withdrawalService.getUserTransactions();
});