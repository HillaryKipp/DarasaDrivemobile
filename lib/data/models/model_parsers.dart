import '../../domain/entities/admin_user.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/school.dart';
import '../../domain/entities/test_attempt.dart';
import '../../domain/entities/unit.dart';

Unit unitFromJson(Map<String, dynamic> json) => Unit(
      id: json['id'] as String,
      unitNumber: json['unit_number'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
    );

Question questionFromJson(Map<String, dynamic> json) => Question(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      questionText: json['question_text'] as String,
      imageUrl: json['image_url'] as String?,
      optionA: json['option_a'] as String,
      optionB: json['option_b'] as String,
      optionC: json['option_c'] as String,
      optionD: json['option_d'] as String,
      correctOption: json['correct_option'] as String,
      explanation: json['explanation'] as String?,
    );

UserProfile profileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      hasPaid: json['has_paid'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );

School schoolFromJson(Map<String, dynamic> json) => School(
      id: json['id'] as String,
      name: json['name'] as String,
      county: json['county'] as String,
      town: json['town'] as String,
      description: json['description'] as String?,
      contactPhone: json['contact_phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      priceFrom: (json['price_from'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt(),
      instructorsCount: (json['instructors_count'] as num?)?.toInt() ?? 0,
      vehicleCategories: (json['vehicle_categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );

Booking bookingFromJson(Map<String, dynamic> json) {
  final schools = json['schools'];
  return Booking(
    id: json['id'] as String,
    schoolId: json['school_id'] as String,
    schoolName: schools is Map ? schools['name'] as String? : null,
    vehicleCategory: json['vehicle_category'] as String,
    scheduledDate: json['scheduled_date'] as String,
    amount: (json['amount'] as num).toInt(),
    status: json['status'] as String? ?? 'pending',
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );
}

MaterialItem materialFromJson(Map<String, dynamic> json) {
  final units = json['units'];
  return MaterialItem(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    type: json['type'] as String,
    url: json['url'] as String,
    isFree: json['is_free'] as bool? ?? false,
    thumbnailUrl: json['thumbnail_url'] as String?,
    unitNumber: units is Map ? units['unit_number'] as int? : null,
    unitTitle: units is Map ? units['title'] as String? : null,
  );
}

TestAttempt testAttemptFromJson(Map<String, dynamic> json) {
  final units = json['units'];
  return TestAttempt(
    id: json['id'] as String,
    unitId: json['unit_id'] as String,
    unitTitle: units is Map ? units['title'] as String? : null,
    unitNumber: units is Map ? units['unit_number'] as int? : null,
    score: (json['score'] as num).toInt(),
    total: (json['total'] as num).toInt(),
    completedAt: DateTime.parse(json['completed_at'] as String),
  );
}

PaymentRecord paymentFromJson(Map<String, dynamic> json) => PaymentRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      purpose: json['purpose'] as String?,
      mpesaReceipt: json['mpesa_receipt'] as String? ??
          json['mpesa_receipt_number'] as String? ??
          json['receipt_number'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );

AdminUser adminUserFromJson(
  Map<String, dynamic> profileJson,
  bool isAdmin,
) =>
    AdminUser(
      profile: profileFromJson(profileJson),
      isAdmin: isAdmin,
    );
