// lib/data/repositories/payment_repository_impl.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final SupabaseClient _client;
  final http.Client _http;

  PaymentRepositoryImpl(this._client, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  @override
  Future<void> requestStkPush({
    required String email,
    required String phone,
    required int amount,
  }) async {
    final body = {
      "email": email,
      "phone": phone,
      "amount": amount,
      "purpose": "account_unlock",
      "user_id": null,
    };

    final uri = Uri.parse(
        'https://project--bb500606-2c15-4a45-8b76-5b135f0ce600.lovable.app/api/public/mpesa/stk');

    developer.log('--- STK PUSH REQUEST ---', name: 'PaymentRepo');
    developer.log('Body: ${jsonEncode(body)}', name: 'PaymentRepo');

    http.Response response;
    try {
      response = await _http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      developer.log('Network error: $e', name: 'PaymentRepo');
      throw AppException("Unable to reach payment server. Check your internet.");
    }

    developer.log('Status code: ${response.statusCode}', name: 'PaymentRepo');
    developer.log('Raw body: ${response.body}', name: 'PaymentRepo');

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Failed to parse JSON: $e', name: 'PaymentRepo');
    }

    // 1. Rate limiting — a prompt was already sent recently
    if (response.statusCode == 429) {
      throw AppException(
        data?['error']?.toString() ??
            "Too many requests. Please wait 2 minutes before retrying.",
      );
    }

    // 2. Success or accepted (200 / 202) — prompt sent, may still be pending
    if (response.statusCode == 200 || response.statusCode == 202) {
      if (data != null && data['ok'] == false) {
        throw AppException(data['error']?.toString() ?? "Transaction failed");
      }
      // ok == true (with or without pending:true) -> treat as success
      return;
    }

    // 3. Everything else is a hard failure
    throw AppException(
      data?['error']?.toString() ?? "STK Push failed. Please try again.",
    );
  }

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
    if (bookingId != null) {
      body['booking_id'] = bookingId;
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/public/mpesa/stk');

    developer.log('--- STK PUSH REQUEST ---', name: 'PaymentRepo');
    developer.log('Body: ${jsonEncode(body)}', name: 'PaymentRepo');

    http.Response response;
    try {
      response = await _http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      developer.log('Network error: $e', name: 'PaymentRepo');
      throw AppException('Unable to reach payment server. Check your internet.');
    }

    developer.log('Status code: ${response.statusCode}', name: 'PaymentRepo');
    developer.log('Raw body: ${response.body}', name: 'PaymentRepo');

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Failed to parse JSON: $e', name: 'PaymentRepo');
    }

    if (response.statusCode == 429) {
      throw AppException(
        data?['error']?.toString() ??
            'Too many requests. Please wait 2 minutes before retrying.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 202) {
      if (data != null && data['ok'] == false) {
        throw AppException(data['error']?.toString() ?? 'Transaction failed');
      }
      return;
    }

    throw AppException(
      data?['error']?.toString() ?? 'STK Push failed. Please try again.',
    );
  }

  @override
  Future<bool> hasCompletedUnlockPayment({
    required String email,
    required String phone,
  }) async {
    try {
      final payment = await _client
          .from('payments')
          .select('status')
          .eq('email', email)
          .eq('phone', phone)
          .eq('purpose', 'account_unlock')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return payment != null && payment['status'] == 'completed';
    } catch (e) {
      developer.log('Payment lookup error: $e', name: 'PaymentRepo');
      return false;
    }
  }

  @override
  Future<bool> waitForUnlock(String userId, {int maxAttempts = 30}) async {
    developer.log('--- WAITING FOR UNLOCK (userId=$userId) ---', name: 'PaymentRepo');

    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final profile = await _client
            .from('profiles')
            .select('has_paid')
            .eq('id', userId)
            .single();

        developer.log('Attempt ${i + 1}/$maxAttempts -> $profile', name: 'PaymentRepo');

        if (profile['has_paid'] == true) {
          developer.log('Payment confirmed', name: 'PaymentRepo');
          return true;
        }
      } catch (e) {
        developer.log('Polling error: $e', name: 'PaymentRepo');
      }
    }

    developer.log('Payment NOT confirmed after $maxAttempts attempts', name: 'PaymentRepo');
    return false;
  }

  @override
  Future<bool> waitForUnlockByContact({
    required String email,
    required String phone,
    int maxAttempts = 30,
  }) async {
    developer.log('--- WAITING FOR UNLOCK (email=$email, phone=$phone) ---', name: 'PaymentRepo');

    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final payment = await _client
            .from('payments')
            .select('status')
            .eq('email', email)
            .eq('phone', phone)
            .eq('purpose', 'account_unlock')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        developer.log('Attempt ${i + 1}/$maxAttempts -> $payment', name: 'PaymentRepo');

        if (payment != null && payment['status'] == 'completed') {
          developer.log('Payment confirmed', name: 'PaymentRepo');
          return true;
        }
      } catch (e) {
        developer.log('Polling error: $e', name: 'PaymentRepo');
      }
    }

    developer.log('Payment NOT confirmed after $maxAttempts attempts', name: 'PaymentRepo');
    return false;
  }
}