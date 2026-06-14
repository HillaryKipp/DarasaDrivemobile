import '../entities/admin_user.dart';
import '../entities/material_item.dart';
import '../entities/payment_record.dart';
import '../entities/profile.dart';
import '../entities/question.dart';
import '../entities/school.dart';
import '../entities/unit.dart';

abstract class AdminRepository {
  // Units
  Future<Unit> createUnit({
    required int unitNumber,
    required String title,
    String? description,
    required bool isFreePreview,
  });
  Future<Unit> updateUnit({
    required String id,
    required int unitNumber,
    required String title,
    String? description,
    required bool isFreePreview,
  });
  Future<void> deleteUnit(String id);

  // Questions
  Future<List<Question>> getQuestions(String unitId);
  Future<Question> createQuestion({
    required String unitId,
    required String questionText,
    String? imageUrl,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctOption,
    String? explanation,
  });
  Future<Question> updateQuestion({
    required String id,
    required String unitId,
    required String questionText,
    String? imageUrl,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctOption,
    String? explanation,
  });
  Future<void> deleteQuestion(String id);

  // Materials
  Future<MaterialItem> createMaterial({
    required String title,
    String? description,
    required String type,
    required String url,
    required bool isFree,
    String? thumbnailUrl,
    String? unitId,
  });
  Future<MaterialItem> updateMaterial({
    required String id,
    required String title,
    String? description,
    required String type,
    required String url,
    required bool isFree,
    String? thumbnailUrl,
    String? unitId,
  });
  Future<void> deleteMaterial(String id);

  // Schools
  Future<School> createSchool({
    required String name,
    required String county,
    required String town,
    String? description,
    String? contactPhone,
    String? logoUrl,
    required int priceFrom,
    double? rating,
    int? reviewCount,
    required int instructorsCount,
    required List<String> vehicleCategories,
  });
  Future<School> updateSchool({
    required String id,
    required String name,
    required String county,
    required String town,
    String? description,
    String? contactPhone,
    String? logoUrl,
    required int priceFrom,
    double? rating,
    int? reviewCount,
    required int instructorsCount,
    required List<String> vehicleCategories,
  });
  Future<void> deleteSchool(String id);

  // Users
  Future<List<AdminUser>> getAllUsers();
  Future<UserProfile> updateUserProfile({
    required String id,
    String? fullName,
    String? phone,
    bool? hasPaid,
  });
  Future<void> setAdminRole({required String userId, required bool isAdmin});

  // Payments
  Future<List<PaymentRecord>> getPayments();
}
