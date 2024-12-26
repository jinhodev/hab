import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _currencyFormat = NumberFormat('#,###');
  bool _isExpense = true;

  List<PieChartSectionData> _getSections(
      Map<String, int> categoryTotals, int total) {
    final List<PieChartSectionData> sections = [];

    categoryTotals.forEach((category, amount) {
      final double percentage = total != 0 ? (amount / total) * 100 : 0;
      if (percentage > 0) {
        sections.add(
          PieChartSectionData(
            value: percentage,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            color: _getCategoryColor(category),
          ),
        );
      }
    });

    return sections;
  }

  Color _getCategoryColor(String category) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFFFBE0B),
      const Color(0xFF96CEB4),
      const Color(0xFF4D96FF),
      const Color(0xFF9C6DFF),
      const Color(0xFF6BCB77),
      const Color(0xFFFF9F45),
    ];

    return colors[category.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final currentMonth = DateTime.now();
    final total =
        provider.getTotalForMonth(currentMonth, isExpense: _isExpense);
    final categoryTotals =
        provider.getCategoryTotals(currentMonth, isExpense: _isExpense);

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2B2B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '분석',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 지출/수입 토글
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF404040),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFF505050)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = (constraints.maxWidth - 8) / 2;
                  return Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: _isExpense
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: buttonWidth,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _isExpense
                                ? const Color(0xFFFF6666)
                                : const Color(0xFF438BFF),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _isExpense = true),
                              child: Center(
                                child: Text(
                                  '지출',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isExpense
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _isExpense = false),
                              child: Center(
                                child: Text(
                                  '수입',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: !_isExpense
                                        ? Colors.white
                                        : Colors.grey[300],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // 총액 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${currentMonth.month}월 ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFC7C7C7),
                  ),
                ),
                Text(
                  '총 ${_isExpense ? '지출' : '수입'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isExpense
                        ? const Color(0xFFFF6666)
                        : const Color(0xFF438BFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${_currencyFormat.format(total.abs())}원',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // 총액 표시 아래에 추가
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF404040),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '지난달 대비',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (context) {
                      final previousTotal = provider.getTotalForPreviousMonth(
                        currentMonth,
                        isExpense: _isExpense,
                      );
                      final difference = total.abs() - previousTotal.abs();
                      final percentChange = previousTotal != 0
                          ? (difference / previousTotal.abs() * 100)
                          : 0.0;

                      final isIncrease = difference > 0;
                      final color = _isExpense
                          ? (isIncrease ? Colors.red[400] : Colors.green[400])
                          : (isIncrease ? Colors.green[400] : Colors.red[400]);

                      return Row(
                        children: [
                          Icon(
                            isIncrease
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_currencyFormat.format(difference.abs())}원',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${percentChange.abs().toStringAsFixed(1)}%)',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // 파이 차트
          if (total != 0) ...[
            const SizedBox(height: 32),
            const Text(
              '카테고리별 비율',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getSections(categoryTotals, total.abs()),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 범례
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: categoryTotals.entries.map((entry) {
                  final percentage = ((entry.value / total.abs()) * 100);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.key} (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                '데이터가 없습니다.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
