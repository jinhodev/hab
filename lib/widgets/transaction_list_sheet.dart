import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionListSheet extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final bool isExpense;

  const TransactionListSheet({
    super.key,
    required this.date,
    required this.transactions,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF2B2B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                DateFormat('yyyy년 MM월 dd일').format(date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isExpense ? '지출' : '수입',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isExpense
                      ? const Color(0xFFFF6666)
                      : const Color(0xFF438BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Center(
              child: Text(
                isExpense ? '지출 내역이 없습니다.' : '수입 내역이 없습니다.',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      title: Text(
                        transaction.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        transaction.category,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: Text(
                        NumberFormat('#,###원').format(transaction.amount.abs()),
                        style: TextStyle(
                          fontSize: 16,
                          color: isExpense
                              ? const Color(0xFFFF6666)
                              : const Color(0xFF438BFF),
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
