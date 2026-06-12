import 'package:equatable/equatable.dart';

class School extends Equatable {
  const School({
    required this.id,
    required this.name,
    required this.county,
    required this.town,
    this.description,
    this.contactPhone,
    this.logoUrl,
    required this.priceFrom,
    this.rating,
    this.reviewCount,
    required this.instructorsCount,
    required this.vehicleCategories,
  });

  final String id;
  final String name;
  final String county;
  final String town;
  final String? description;
  final String? contactPhone;
  final String? logoUrl;
  final int priceFrom;
  final double? rating;
  final int? reviewCount;
  final int instructorsCount;
  final List<String> vehicleCategories;

  @override
  List<Object?> get props => [id];
}
