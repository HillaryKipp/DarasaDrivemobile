import 'package:equatable/equatable.dart';

import 'profile.dart';

class AdminUser extends Equatable {
  const AdminUser({
    required this.profile,
    required this.isAdmin,
  });

  final UserProfile profile;
  final bool isAdmin;

  @override
  List<Object?> get props => [profile.id, isAdmin];
}
