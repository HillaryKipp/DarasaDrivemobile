import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/question.dart';
import '../../domain/entities/test_attempt.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/units_repository.dart';
import '../models/model_parsers.dart';

class UnitsRepositoryImpl implements UnitsRepository {
  UnitsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Unit>> getUnits() async {
    final data = await _client.from('units').select().order('unit_number');
    return (data as List)
        .map((e) => unitFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Unit> getUnit(String id) async {
    final data =
        await _client.from('units').select().eq('id', id).single();
    return unitFromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Question>> getQuestions(String unitId) async {
    final data =
        await _client.from('questions').select().eq('unit_id', unitId);
    final questions = (data as List)
        .map((e) => questionFromJson(Map<String, dynamic>.from(e)))
        .toList();
    questions.shuffle();
    return questions;
  }

  @override
  Future<void> saveTestAttempt({
    required String userId,
    required String unitId,
    required int score,
    required int total,
    required List<String> wrongQuestionIds,
  }) async {
    try {
      debugPrint('--- DB SAVE START: Unit=$unitId Score=$score ---');
      
      // Upsert: Updates existing row if user_id+unit_id matches, else inserts.
      final response = await _client.from('test_attempts').upsert({
        'user_id': userId,
        'unit_id': unitId,
        'score': score,
        'total': total,
        'wrong_question_ids': wrongQuestionIds,
        'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,unit_id').select();
      
      if (response.isEmpty) {
        debugPrint('--- DB WARNING: Save returned no data. Check if your RLS Policy allows UPDATE! ---');
      } else {
        debugPrint('--- DB SUCCESS: Row updated in database ---');
      }
    } on PostgrestException catch (e) {
      debugPrint('--- DB ERROR: ${e.message} (Code: ${e.code}) ---');
      rethrow;
    } catch (e) {
      debugPrint('--- DB CRITICAL ERROR: $e ---');
      rethrow;
    }
  }

  @override
  Future<List<TestAttempt>> getTestAttempts(String userId) async {
    final data = await _client
        .from('test_attempts')
        .select('*, units(title, unit_number)')
        .eq('user_id', userId)
        .order('completed_at', ascending: false);
    return (data as List)
        .map((e) => testAttemptFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
