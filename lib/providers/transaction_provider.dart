import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';

class TransactionProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();
  List<Transaction> _transactions = [];
  List<String> _expenseCategories = [];
  List<String> _incomeCategories = [];
  bool _isLoading = false;

  // 기본 카테고리 정의
  static const List<String> defaultExpenseCategories = [
    '식비',
    '문화생활',
    '교통비',
    '쇼핑',
    '의료',
  ];

  static const List<String> defaultIncomeCategories = [
    '급여',
    '용돈',
    '이자',
    '기타수입',
  ];

  // 캐시 추가
  final Map<String, List<Transaction>> _dateTransactionsCache = {};

  List<Transaction> get transactions => _transactions;
  List<String> get expenseCategories => _expenseCategories;
  List<String> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

  Future<void> initializeDefaultCategories() async {
    try {
      // 카테고리 로드해서 확인
      final existingExpenseCategories =
          await _supabaseService.getCategories(isExpense: true);
      final existingIncomeCategories =
          await _supabaseService.getCategories(isExpense: false);

      // 카테고리가 하나도 없을 때만 기본 카테고리 추가
      if (existingExpenseCategories.isEmpty &&
          existingIncomeCategories.isEmpty) {
        // 지출 카테고리 초기화
        for (String category in defaultExpenseCategories) {
          await _supabaseService.addCategory(
            name: category,
            isExpense: true,
          );
        }

        // 수입 카테고리 초기화
        for (String category in defaultIncomeCategories) {
          await _supabaseService.addCategory(
            name: category,
            isExpense: false,
          );
        }
      }

      // 카테고리 즉시 로드
      _expenseCategories =
          await _supabaseService.getCategories(isExpense: true);
      _incomeCategories =
          await _supabaseService.getCategories(isExpense: false);
      notifyListeners();
    } catch (e) {
      print('Error initializing default categories: $e');
    }
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _supabaseService.getTransactions();
      _clearCache(); // 캐시 초기화

      // 그 다음 카테고리 로드
      _expenseCategories =
          await _supabaseService.getCategories(isExpense: true);
      _incomeCategories =
          await _supabaseService.getCategories(isExpense: false);

      // 카테고리가 없을 때만 기본 카테고리 초기화
      if (_expenseCategories.isEmpty && _incomeCategories.isEmpty) {
        await initializeDefaultCategories();
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Transaction> getTransactionsForDate(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';

    if (!_dateTransactionsCache.containsKey(key)) {
      _dateTransactionsCache[key] = _transactions.where((transaction) {
        return transaction.date.year == date.year &&
            transaction.date.month == date.month &&
            transaction.date.day == date.day;
      }).toList();
    }

    return _dateTransactionsCache[key]!;
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final savedTransaction =
          await _supabaseService.addTransaction(transaction);
      _transactions.add(savedTransaction);
      _clearCache();
      notifyListeners();
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> addCategory(String category, bool isExpense) async {
    try {
      await _supabaseService.addCategory(
        name: category,
        isExpense: isExpense,
      );

      if (isExpense) {
        _expenseCategories.add(category);
      } else {
        _incomeCategories.add(category);
      }
      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String category, bool isExpense) async {
    try {
      await _supabaseService.deleteCategory(
        name: category,
        isExpense: isExpense,
      );

      // 로컬 상태 업데이트
      if (isExpense) {
        _expenseCategories.remove(category);
      } else {
        _incomeCategories.remove(category);
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  int getTotalForMonth(DateTime date, {required bool isExpense}) {
    return _transactions
        .where((transaction) =>
            transaction.date.year == date.year &&
            transaction.date.month == date.month &&
            transaction.isExpense == isExpense)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  int getTotalForPreviousMonth(DateTime date, {required bool isExpense}) {
    final previousMonth = DateTime(date.year, date.month - 1);
    return _transactions
        .where((transaction) =>
            transaction.date.year == previousMonth.year &&
            transaction.date.month == previousMonth.month &&
            transaction.isExpense == isExpense)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  Future<void> refreshTransactions() async {
    await loadInitialData();
  }

  Map<String, int> getCategoryTotals(DateTime date, {required bool isExpense}) {
    final Map<String, int> totals = {};

    _transactions
        .where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.isExpense == isExpense)
        .forEach((t) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount.abs();
    });

    return totals;
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      // 먼저 로컬 상태 업데이트
      _transactions.removeWhere((t) => t.id == transaction.id);
      _clearCache();
      notifyListeners();

      // 서버에서 삭제
      await _supabaseService.deleteTransaction(transaction);
    } catch (e) {
      // 실패 시 서버에서 다시 로드
      _transactions = await _supabaseService.getTransactions();
      _clearCache();
      notifyListeners();
      rethrow;
    }
  }

  // 캐시 초기화 추가
  void _clearCache() {
    _dateTransactionsCache.clear();
  }
}
