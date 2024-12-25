import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'widgets/add_category_dialog.dart';

class AddExpensePage extends StatefulWidget {
  final DateTime selectedDate;
  final bool isExpense;

  const AddExpensePage({
    super.key,
    required this.selectedDate,
    required this.isExpense,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  late bool _isExpense;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _titleFocusNode = FocusNode();
  String? _selectedCategory;
  bool _isEditMode = false;

  // 기본 카테고리 색상 맵
  final Map<String, Color> _defaultColors = {
    '식비': const Color(0xFFFF6B6B),
    '문화생활': const Color(0xFF4ECDC4),
    '교통비': const Color(0xFF45B7D1),
    '쇼핑': const Color(0xFFFFBE0B),
    '의료': const Color(0xFF96CEB4),
    '급여': const Color(0xFF4D96FF),
    '용돈': const Color(0xFF9C6DFF),
    '이자': const Color(0xFF6BCB77),
    '기타 수입': const Color(0xFFFF9F45),
  };

  // 랜덤 색상 리스트
  final List<Color> _randomColors = [
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

  // 카테고리별 색상 캐시
  final Map<String, Color> _categoryColors = {};

  // Provider에서 카테고리 가져오기
  List<String> get _categories => _isExpense
      ? context.watch<TransactionProvider>().expenseCategories
      : context.watch<TransactionProvider>().incomeCategories;

  // 카테고리 색상 가져오기
  Color _getCategoryColor(String category) {
    // 이미 캐시된 색상이 있으면 반환
    if (_categoryColors.containsKey(category)) {
      return _categoryColors[category]!;
    }

    // 기본 카테고리 색상이 있으면 반환
    if (_defaultColors.containsKey(category)) {
      _categoryColors[category] = _defaultColors[category]!;
      return _defaultColors[category]!;
    }

    // 새로운 카테고리면 랜덤 색상 할당
    final color =
        _randomColors[DateTime.now().microsecond % _randomColors.length];
    _categoryColors[category] = color;
    return color;
  }

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpense;
    _selectedCategory = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_titleFocusNode);
      }
    });

    _amountController.addListener(() {
      String text = _amountController.text;
      if (text.isEmpty) return;

      text = text.replaceAll(',', '').replaceAll('원', '');
      if (text.isEmpty) return;

      if (int.tryParse(text) == null) return;

      final cursorPosition = _amountController.selection.start;

      final formattedNumber = NumberFormat('#,###').format(int.parse(text));

      if (_amountController.text != formattedNumber) {
        _amountController.text = formattedNumber;

        if (cursorPosition != -1) {
          final newPosition =
              cursorPosition + (formattedNumber.length - text.length);
          _amountController.selection = TextSelection.fromPosition(
            TextPosition(offset: newPosition),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _addTransaction() {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해주세요.')),
      );
      return;
    }

    final transaction = Transaction(
      title: _titleController.text,
      amount: _isExpense ? -amount : amount,
      category: _selectedCategory!,
      date: widget.selectedDate,
      isExpense: _isExpense,
    );

    context.read<TransactionProvider>().addTransaction(transaction);

    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isExpense ? '지출이 추가되었습니다.' : '수입이 추가되었습니다.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor:
            _isExpense ? const Color(0xFFFF6666) : const Color(0xFF438BFF),
        duration: const Duration(seconds: 1), // 1초 동안 표시
      ),
    );

    Navigator.pop(context);
  }

  // 카테고리 추가 메서드 수정
  Future<void> _showAddCategoryDialog() async {
    String? newCategory;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AddCategoryDialog(
          isExpense: _isExpense,
          onSave: (category) {
            newCategory = category;
          },
        );
      },
    );

    if (newCategory != null && newCategory!.isNotEmpty) {
      try {
        await context.read<TransactionProvider>().addCategory(
              newCategory!,
              _isExpense,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카테고리 추가에 실패했습니다.')),
          );
        }
      }
    }
  }

  // 카테고리 삭제 메서드 수정
  void _deleteCategory(String category) async {
    try {
      await context.read<TransactionProvider>().deleteCategory(
            category,
            _isExpense,
          );
      if (_selectedCategory == category) {
        setState(() {
          _selectedCategory = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카테고리 삭제에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isEditMode) {
          setState(() {
            _isEditMode = false;
          });
        }
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2B2B2B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isExpense ? '지출 추가하기' : '수입 추가하기',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: const Color(0xFF2B2B2B),
                    child: GestureDetector(
                      onTap: () {
                        if (_isEditMode) {
                          setState(() {
                            _isEditMode = false;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isExpense ? '지출' : '수입',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '제목',
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                floatingLabelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                suffixIcon: _titleController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          _titleController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _amountController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '금액',
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                floatingLabelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                suffixIcon: _amountController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          _amountController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {});
                                if (value.isNotEmpty) {
                                  final number = value.replaceAll(',', '');
                                  if (int.tryParse(number) == null) {
                                    _amountController.text =
                                        value.substring(0, value.length - 1);
                                    _amountController.selection =
                                        TextSelection.collapsed(
                                      offset: _amountController.text.length,
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 54),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  '카테고리',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -2),
                                  child: IconButton(
                                    onPressed: _showAddCategoryDialog,
                                    iconSize: 18,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 12,
                                children: [
                                  ..._categories.map((category) {
                                    return GestureDetector(
                                      onLongPress: () {
                                        setState(() {
                                          _isEditMode = true;
                                        });
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          GestureDetector(
                                            onTap: _isEditMode
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _selectedCategory =
                                                          category ==
                                                                  _selectedCategory
                                                              ? null
                                                              : category;
                                                    });
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                  },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: category ==
                                                        _selectedCategory
                                                    ? _getCategoryColor(
                                                        category)
                                                    : const Color(0xFF404040),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                  color: category ==
                                                          _selectedCategory
                                                      ? Colors.white
                                                      : Colors.grey[300],
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_isEditMode)
                                            Positioned(
                                              right: -6,
                                              top: -6,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _deleteCategory(category),
                                                child: Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[400],
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xFF2B2B2B),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  if (_isEditMode)
                                    GestureDetector(
                                      onTap: _showAddCategoryDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF404040),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.grey[600]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline,
                                              size: 16,
                                              color: Colors.grey[300],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '카테고리 추가',
                                              style: TextStyle(
                                                color: Colors.grey[300],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _addTransaction,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isExpense
                          ? const Color(0xFFFF6666)
                          : const Color(0xFF438BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '추가하기',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
