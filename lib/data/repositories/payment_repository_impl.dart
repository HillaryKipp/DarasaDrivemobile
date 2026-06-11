import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._client, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  @override
  Future<void> initiateStkPush({
    required String email,
    required String phone,
    required int amount,
    required String purpose,
    String? userId,
    String? bookingId,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'phone': phone,
      'amount': amount,
      'purpose': purpose,
      'user_id': userId,
    };
    if (bookingId != null) body['booking_id'] = bookingId;

    final response = await _http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/public/mpesa/stk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AppException(data['error']?.toString() ?? 'STK push failed');
    }
  }

  @override
  Future<bool> waitForUnlock(String userId, {int maxAttempts = 30}) async {
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      final profile = await _client
          .from('profiles')
          .select('has_paid')
          .eq('id', userId)
          .single();
      if (profile['has_paid'] == true) return true;
    }
    return false;
  }
}
