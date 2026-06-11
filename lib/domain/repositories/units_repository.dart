import '../entities/question.dart';
import '../entities/test_attempt.dart';
import '../entities/unit.dart';

abstract class UnitsRepository {
  Future<List<Unit>> getUnits();
  Future<Unit> getUnit(String id);
  Future<List<Question>> getQuestions(String unitId);
  Future<void> saveTestAttempt({
    required String userId,
    required String unitId,
    required int score,
    required int total,
    required List<String> wrongQuestionIds,
  });
  Future<List<TestAttempt>> getTestAttempts(String userId);
}
