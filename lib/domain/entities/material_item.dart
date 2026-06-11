import 'package:equatable/equatable.dart';

class MaterialItem extends Equatable {
  const MaterialItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.url,
    required this.isFree,
    this.thumbnailUrl,
    this.unitNumber,
    this.unitTitle,
  });

  final String id;
  final String title;
  final String? description;
  final String type;
  final String url;
  final bool isFree;
  final String? thumbnailUrl;
  final int? unitNumber;
  final String? unitTitle;

  bool isAccessible(bool hasPaid) => isFree || hasPaid;

  @override
  List<Object?> get props => [id];
}
