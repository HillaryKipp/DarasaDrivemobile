import 'package:equatable/equatable.dart';

class Question extends Equatable {
  const Question({
    required this.id,
    required this.unitId,
    required this.questionText,
    this.imageUrl,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation,
  });

  final String id;
  final String unitId;
  final String questionText;
  final String? imageUrl;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String? explanation;

  Map<String, String> get options => {
        'A': optionA,
        'B': optionB,
        'C': optionC,
        'D': optionD,
      };

  String optionLabel(String key) => options[key] ?? '';

  @override
  List<Object?> get props => [id];
}
