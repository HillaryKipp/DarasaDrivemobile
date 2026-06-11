import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.schoolId,
    this.schoolName,
    required this.vehicleCategory,
    required this.scheduledDate,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String? schoolName;
  final String vehicleCategory;
  final String scheduledDate;
  final int amount;
  final String status;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id];
}
