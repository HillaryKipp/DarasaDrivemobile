import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/booking.dart';
import '../../domain/entities/school.dart';
import '../../domain/repositories/schools_repository.dart';
import '../models/model_parsers.dart';

class SchoolsRepositoryImpl implements SchoolsRepository {
  SchoolsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<School>> getSchools() async {
    final data =
        await _client.from('schools').select().order('rating', ascending: false);
    return (data as List)
        .map((e) => schoolFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<School> getSchool(String id) async {
    final data =
        await _client.from('schools').select().eq('id', id).single();
    return schoolFromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<Booking> createBooking({
    required String userId,
    required String schoolId,
    required String vehicleCategory,
    required String scheduledDate,
    required int amount,
  }) async {
    final data = await _client
        .from('bookings')
        .insert({
          'user_id': userId,
          'school_id': schoolId,
          'vehicle_category': vehicleCategory,
          'scheduled_date': scheduledDate,
          'amount': amount,
          'status': 'confirmed',
        })
        .select()
        .single();
    return bookingFromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    final data = await _client
        .from('bookings')
        .select('*, schools(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => bookingFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
