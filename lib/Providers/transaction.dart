import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transactionRequest.dart';
import 'package:shared_preferences/shared_preferences.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super([]);

  Future<void> fetchTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      if (userData == null) {
        print('User not logged in');
        state = [];
        return;
      }

      final extract = jsonDecode(userData) as Map<String, dynamic>;
      final userId = extract['user_id'];

      final res = await http.get(
        Uri.parse('http://www.gocodedesigners.com/bbtransactonhistory'),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data = json['data'];
        final allTransactions = data.map((e) => Transaction.fromJson(e)).toList();
        state = allTransactions.where((tx) => tx.userId == userId).toList();
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

}
