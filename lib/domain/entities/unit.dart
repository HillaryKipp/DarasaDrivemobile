import 'package:equatable/equatable.dart';

class Unit extends Equatable {
  const Unit({
    required this.id,
    required this.unitNumber,
    required this.title,
    this.description,
    required this.isFreePreview,
  });

  final String id;
  final int unitNumber;
  final String title;
  final String? description;
  final bool isFreePreview;

  bool isAccessible(bool hasPaid) => hasPaid || isFreePreview;

  @override
  List<Object?> get props => [id, unitNumber, title, isFreePreview];
}
