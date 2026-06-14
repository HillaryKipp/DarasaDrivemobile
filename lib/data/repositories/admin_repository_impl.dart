import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/payment_record.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/school.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/admin_repository.dart';
import '../models/model_parsers.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._client);

  final SupabaseClient _client;

  Future<T> _wrap<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  @override
  Future<Unit> createUnit({
    required int unitNumber,
    required String title,
    String? description,
    required bool isFreePreview,
  }) =>
      _wrap(() async {
        final data = await _client.from('units').insert({
          'unit_number': unitNumber,
          'title': title,
          'description': description,
          'is_free_preview': isFreePreview,
        }).select().single();
        return unitFromJson(Map<String, dynamic>.from(data));
      });

  @override
  Future<Unit> updateUnit({
    required String id,
    required int unitNumber,
    required String title,
    String? description,
    required bool isFreePreview,
  }) =>
      _wrap(() async {
        final data = await _client.from('units').update({
          'unit_number': unitNumber,
          'title': title,
          'description': description,
          'is_free_preview': isFreePreview,
        }).eq('id', id).select().single();
        return unitFromJson(Map<String, dynamic>.from(data));
      });

  @override
  Future<void> deleteUnit(String id) =>
      _wrap(() => _client.from('units').delete().eq('id', id));

  @override
  Future<List<Question>> getQuestions(String unitId) =>
      _wrap(() async {
        final data = await _client
            .from('questions')
            .select()
            .eq('unit_id', unitId);
        return (data as List)
            .map((e) => questionFromJson(Map<String, dynamic>.from(e)))
            .toList();
      });

  @override
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
  }) =>
      _wrap(() async {
        final data = await _client.from('questions').insert({
          'unit_id': unitId,
          'question_text': questionText,
          'image_url': imageUrl,
          'option_a': optionA,
          'option_b': optionB,
          'option_c': optionC,
          'option_d': optionD,
          'correct_option': correctOption,
          'explanation': explanation,
        }).select().single();
        return questionFromJson(Map<String, dynamic>.from(data));
      });

  @override
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
  }) =>
      _wrap(() async {
        final data = await _client.from('questions').update({
          'unit_id': unitId,
          'question_text': questionText,
          'image_url': imageUrl,
          'option_a': optionA,
          'option_b': optionB,
          'option_c': optionC,
          'option_d': optionD,
          'correct_option': correctOption,
          'explanation': explanation,
        }).eq('id', id).select().single();
        return questionFromJson(Map<String, dynamic>.from(data));
      });

  @override
  Future<void> deleteQuestion(String id) =>
      _wrap(() => _client.from('questions').delete().eq('id', id));

  Map<String, dynamic> _materialPayload({
    required String title,
    String? description,
    required String type,
    required String url,
    required bool isFree,
    String? thumbnailUrl,
    String? unitId,
  }) =>
      {
        'title': title,
        'description': description,
        'type': type,
        'url': url,
        'is_free': isFree,
        'thumbnail_url': thumbnailUrl,
        'unit_id': unitId,
      };

  @override
  Future<MaterialItem> createMaterial({
    required String title,
    String? description,
    required String type,
    required String url,
    required bool isFree,
    String? thumbnailUrl,
    String? unitId,
  }) =>
      _wrap(() async {
        final data = await _client
            .from('materials')
            .insert(_materialPayload(
              title: title,
              description: description,
              type: type,
              url: url,
              isFree: isFree,
              thumbnailUrl: thumbnailUrl,
              unitId: unitId,
            ))
            .select('*, units(unit_number, title)')
            .single();
        return materialFromJson(Map<String, dynamic>.from(data));
      });

  @override
  Future<MaterialItem> updateMaterial({
    required String id,
    required String title,
    String? description,
    required String type,
    required String url,
    required bool isFree,
    String? thumbnailUrl,
    String? unitId,
  }) =>
      _wrap(() async {
        final data = await _client
            .from('materials')
            .update(_materialPayload(
              title: title,
              description: description,
              type: type,
              url: url,
              isFree: isFree,
              thumbnailUrl: thumbnailUrl,
              unitId: unitId,
            ))
            .eq('id', id)
            .select('*, units(unit_number, title)')
            .single();
        return materialFromJson(Map<String, dynamic>.from(data));
      });

  @override
  Future<void> deleteMaterial(String id) =>
      _wrap(() => _client.from('materials').delete().eq('id', id));

  Map<String, dynamic> _schoolPayload({
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
  }) =>
      {
        'name': name,
        'county': county,
        'town': town,
        'description': description,
        'contact_phone': contactPhone,
        'logo_url': logoUrl,
        'price_from': priceFrom,
        'rating': rating,
        'review_count': reviewCount,
        'instructors_count': instructorsCount,
        'vehicle_categories': vehicleCategories,
      };

  @override
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
  }) =>
      _wrap(() async {
        final data = await _client
            .from('schools')
            .insert(_schoolPayload(
              name: name,
              county: county,
              town: town,
              description: description,
              contactPhone: contactPhone,
              logoUrl: logoUrl,
              priceFrom: priceFrom,
              rating: rating,
              reviewCount: reviewCount,
              instructorsCount: instructorsCount,
              vehicleCategories: vehicleCategories,
            ))
            .select()
            .single();
        return schoolFromJson(Map<String, dynamic>.from(data));
      });

  @override
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
  }) =>
      _wrap(() async {
        final data = await _client
            .from('schools')
            .update(_schoolPayload(
              name: name,
              county: county,
              town: town,
              description: description,
              contactPhone: contactPhone,
              logoUrl: logoUrl,
              priceFrom: priceFrom,
              rating: rating,
              reviewCount: reviewCount,
              instructorsCount: instructorsCount,
              vehicleCategories: vehicleCategories,
            ))
            .eq('id', id)
            .select()
            .single();
        return schoolFromJson(Map<String, dynamic>.from(data));
      });

  @override
  Future<void> deleteSchool(String id) =>
      _wrap(() => _client.from('schools').delete().eq('id', id));

  @override
  Future<List<AdminUser>> getAllUsers() => _wrap(() async {
        final profiles = await _client
            .from('profiles')
            .select()
            .order('created_at', ascending: false);
        final roles = await _client.from('user_roles').select('user_id, role');
        final adminIds = (roles as List)
            .where((r) => r['role'] == 'admin')
            .map((r) => r['user_id'] as String)
            .toSet();
        return (profiles as List).map((row) {
          final json = Map<String, dynamic>.from(row);
          return adminUserFromJson(json, adminIds.contains(json['id']));
        }).toList();
      });

  @override
  Future<UserProfile> updateUserProfile({
    required String id,
    String? fullName,
    String? phone,
    bool? hasPaid,
  }) =>
      _wrap(() async {
        final payload = <String, dynamic>{};
        if (fullName != null) payload['full_name'] = fullName;
        if (phone != null) payload['phone'] = phone;
        if (hasPaid != null) payload['has_paid'] = hasPaid;
        final data = await _client
            .from('profiles')
            .update(payload)
            .eq('id', id)
            .select()
            .single();
        return profileFromJson(Map<String, dynamic>.from(data));
      });

  @override
  Future<void> setAdminRole({required String userId, required bool isAdmin}) =>
      _wrap(() async {
        if (isAdmin) {
          final existing = await _client
              .from('user_roles')
              .select()
              .eq('user_id', userId)
              .eq('role', 'admin');
          if ((existing as List).isEmpty) {
            await _client.from('user_roles').insert({
              'user_id': userId,
              'role': 'admin',
            });
          }
        } else {
          await _client
              .from('user_roles')
              .delete()
              .eq('user_id', userId)
              .eq('role', 'admin');
        }
      });

  @override
  Future<List<PaymentRecord>> getPayments() => _wrap(() async {
        final data = await _client
            .from('payments')
            .select()
            .order('created_at', ascending: false);
        return (data as List)
            .map((e) => paymentFromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
}
