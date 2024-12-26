import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class TransactionListSheet extends StatefulWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final bool isExpense;
  final VoidCallback onDelete;

  const TransactionListSheet({
    super.key,
    required this.date,
    required this.transactions,
    required this.isExpense,
    required this.onDelete,
  });

  @override
  State<TransactionListSheet> createState() => _TransactionListSheetState();
}

class _TransactionListSheetState extends State<TransactionListSheet> {
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = List.from(widget.transactions);
  }

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
                DateFormat('yyyy년 MM월 dd일').format(widget.date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isExpense ? '지출' : '수입',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isExpense
                      ? const Color(0xFFFF6666)
                      : const Color(0xFF438BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.transactions.isEmpty)
            Center(
              child: Text(
                widget.isExpense ? '지출 내역이 없습니다.' : '수입 내역이 없습니다.',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return Dismissible(
                      key: Key('${transaction.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red[400],
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF404040),
                              title: const Text(
                                '삭제 확인',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                '이 항목을 삭제하시겠습니까?',
                                style: TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    '취소',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.red[400]),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        final provider = context.read<TransactionProvider>();
                        setState(() {
                          _transactions.removeAt(index);
                        });

                        try {
                          await provider.deleteTransaction(transaction);
                          widget.onDelete();

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('삭제되었습니다'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('삭제에 실패했습니다'),
                            ),
                          );
                        }
                      },
                      child: ListTile(
                        title: Text(
                          transaction.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          transaction.category,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        trailing: Text(
                          NumberFormat('#,###원')
                              .format(transaction.amount.abs()),
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isExpense
                                ? const Color(0xFFFF6666)
                                : const Color(0xFF438BFF),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
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
