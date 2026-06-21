import 'package:equatable/equatable.dart';

class TestAttempt extends Equatable {
  const TestAttempt({
    required this.id,
    required this.unitId,
    this.unitTitle,
    this.unitNumber,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  final String id;
  final String unitId;
  final String? unitTitle;
  final int? unitNumber;
  final int score;
  final int total;
  final DateTime completedAt;

  int get percentage => total == 0 ? 0 : ((score / total) * 100).round();

  @override
  List<Object?> get props => [id, unitId, score, total, completedAt];
}
