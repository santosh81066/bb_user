import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Colors/coustcolors.dart';
import '../Providers/transaction.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(transactionProvider.notifier).fetchTransactions());
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    if (_searchQuery.isEmpty) return transactions;

    final query = _searchQuery.toLowerCase();

    return transactions.where((tx) {
      final paymentId = tx.razorpayPaymentId?.toLowerCase() ?? '';
      final orderId = tx.razorpayOrderId?.toLowerCase() ?? '';
      final userId = tx.userId?.toString().toLowerCase() ?? '';

      return paymentId.contains(query) ||
          orderId.contains(query) ||
          userId.contains(query);
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final filteredTransactions = _filterTransactions(transactions);

    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 10),
          _buildStatsSummary(transactions),
          const SizedBox(height: 10),
          _buildTabHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: transactions.isEmpty
                ? _buildLoadingState()
                : filteredTransactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionsList(filteredTransactions),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFF6418C3),
        borderRadius: BorderRadiusDirectional.only(
          bottomEnd: Radius.circular(30),
          bottomStart: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            const Text(
              "Payment History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search payment ID, order ID...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF6418C3),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Icon(
                Icons.close,
                color: Colors.grey,
                size: 20,
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<dynamic> transactions) {
    final totalAmount = transactions.fold<double>(
        0, (sum, tx) {
      final amount = tx.amount;
      if (amount is int) {
        return sum + amount.toDouble();
      } else if (amount is double) {
        return sum + amount;
      } else if (amount is String) {
        return sum + (double.tryParse(amount) ?? 0);
      }
      return sum;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6418C3), Color(0xFF8C52FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x296418C3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              title: 'Total Payments',
              value: '${transactions.length}',
              icon: Icons.payment,
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white38,
            ),
            _buildStatItem(
              title: 'Total Amount',
              value: '₹ ${totalAmount.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTab(title: 'All', isActive: true),
          _buildTab(title: 'Completed', isActive: false),
          _buildTab(title: 'Failed', isActive: false),
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6418C3) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isActive ? const Color(0x296418C3) : const Color(0x15000000),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey[700],
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6418C3)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading your transactions...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No results found for "$_searchQuery"',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or clear search',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<dynamic> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final hasDate = index % 2 == 0;
        final txDate = hasDate ? DateTime.now().subtract(Duration(days: index)) : null;

        return _buildTransactionCard(tx, txDate);
      },
    );
  }

  Widget _buildTransactionCard(dynamic tx, DateTime? date) {
    String amountDisplay;
    if (tx.amount is int) {
      amountDisplay = "₹ ${tx.amount.toDouble().toStringAsFixed(2)}";
    } else if (tx.amount is double) {
      amountDisplay = "₹ ${tx.amount.toStringAsFixed(2)}";
    } else {
      final parsedAmount = double.tryParse(tx.amount?.toString() ?? '0') ?? 0.0;
      amountDisplay = "₹ ${parsedAmount.toStringAsFixed(2)}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6418C3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF6418C3),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _truncateString(tx.razorpayPaymentId),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            amountDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6418C3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Order ID: ${_truncateString(tx.razorpayOrderId)}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                         /* Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "User: ${_truncateString(tx.userId, maxLength: 8)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),*/
                          if (date != null)
                            Text(
                              DateFormat('dd MMM').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.receipt_outlined,
                    size: 16,
                    color: Color(0xFF6418C3),
                  ),
                  label: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF6418C3),
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _truncateString(dynamic text, {int maxLength = 12}) {
    if (text == null) return '';

    final stringText = text.toString();
    if (stringText.length <= maxLength) {
      return stringText;
    }
    return '${stringText.substring(0, maxLength)}...';
  }
}
