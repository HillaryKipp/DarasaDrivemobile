import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    required this.hasPaid,
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final bool hasPaid;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, hasPaid];
}
