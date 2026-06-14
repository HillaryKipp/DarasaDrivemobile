import 'package:equatable/equatable.dart';

class PaymentRecord extends Equatable {
  const PaymentRecord({
    required this.id,
    this.userId,
    this.email,
    this.phone,
    required this.amount,
    required this.status,
    this.purpose,
    this.mpesaReceipt,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String? email;
  final String? phone;
  final int amount;
  final String status;
  final String? purpose;
  final String? mpesaReceipt;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id];
}
