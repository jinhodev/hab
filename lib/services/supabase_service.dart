import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;

  // 인증 관련 메서드
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // 거래 데이터 관련 메서드
  Future<List<Transaction>> getTransactions() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(100);

    return (response as List)
        .map((data) => Transaction.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      final response = await supabase
          .from('transactions')
          .insert({
            'user_id': userId,
            'title': transaction.title,
            'amount': transaction.amount,
            'category': transaction.category,
            'date': transaction.date.toIso8601String(),
            'is_expense': transaction.isExpense,
          })
          .select()
          .single();

      print('Response from Supabase: $response'); // 디버깅용

      if (response == null) {
        throw Exception('Failed to add transaction');
      }

      return Transaction.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      print('Error in addTransaction: $e'); // 디버깅용
      rethrow;
    }
  }

  // 카테고리 관련 메서드
  Future<List<String>> getCategories({required bool isExpense}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await supabase
        .from('categories')
        .select('name')
        .eq('user_id', userId)
        .eq('is_expense', isExpense)
        .order('created_at');

    return (response as List).map((data) => data['name'] as String).toList();
  }

  Future<void> addCategory({
    required String name,
    required bool isExpense,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await supabase.from('categories').insert({
        'user_id': userId,
        'name': name,
        'is_expense': isExpense,
      });
    } catch (e) {
      // 중복 카테고리 에러 무시
      print('Error adding category (might be duplicate): $e');
    }
  }

  Future<void> deleteCategory({
    required String name,
    required bool isExpense,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await supabase
        .from('categories')
        .delete()
        .eq('user_id', userId)
        .eq('name', name)
        .eq('is_expense', isExpense);
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await supabase.from('transactions').delete().match({
        'id': transaction.id,
        'user_id': userId,
      });

      // 성공적으로 삭제되면 여기까지 실행됨
    } catch (e) {
      print('Error in deleteTransaction: $e');
      rethrow;
    }
  }
}
