// lib/data/repositories/payment_repository_impl.dart
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
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

  void _log(String message) {
    developer.log(message, name: 'PaymentRepo');
    if (kDebugMode) {
      debugPrint('[PaymentRepo] $message');
    }
  }

  bool _isCompletedPayment(Map<String, dynamic>? row) {
    if (row == null) return false;
    final status = row['status']?.toString().toLowerCase();
    return status == 'completed' || status == 'success' || status == 'paid';
  }

  Future<Map<String, dynamic>?> _queryStatus(String checkoutRequestId) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/public/mpesa/status?checkoutRequestId=$checkoutRequestId',
    );
    try {
      final response = await _http.get(uri);
      final data = _parseJsonResponse(response);
      _log('Status query ($checkoutRequestId) -> $data');
      return data;
    } catch (e) {
      _log('Status query error: $e');
      return null;
    }
  }

  Future<({bool profilePaid, bool paymentCompleted, bool paymentFailed})> _fetchUnlockStatus({
    required String userId,
    String? email,
    String? phone,
    String? checkoutRequestId,
  }) async {
    var profilePaid = false;
    var paymentCompleted = false;
    var paymentFailed = false;

    // Actively resolve status via Daraja if we have a checkoutRequestId.
    if (checkoutRequestId != null) {
      final statusResult = await _queryStatus(checkoutRequestId);
      final status = statusResult?['status']?.toString().toLowerCase();
      if (status == 'success') {
        paymentCompleted = true;
      } else if (status == 'failed') {
        paymentFailed = true;
      }
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('has_paid')
          .eq('id', userId)
          .single();
      _log('Profile poll -> $profile');
      profilePaid = profile['has_paid'] == true;
    } catch (e) {
      _log('Profile poll error: $e');
    }

    if (!paymentCompleted && !paymentFailed) {
      try {
        final byUser = await _client
            .from('payments')
            .select('status, mpesa_receipt, created_at')
            .eq('user_id', userId)
            .eq('purpose', AppConfig.unlockPurpose)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        _log('Payment poll (user_id) -> $byUser');
        if (_isCompletedPayment(byUser)) {
          paymentCompleted = true;
        }
      } catch (e) {
        _log('Payment poll (user_id) error: $e');
      }
    }

    if (!paymentCompleted && !paymentFailed && email != null && phone != null) {
      try {
        final byContact = await _client
            .from('payments')
            .select('status, mpesa_receipt, created_at')
            .eq('email', email)
            .eq('phone', phone)
            .eq('purpose', AppConfig.unlockPurpose)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        _log('Payment poll (contact) -> $byContact');
        if (_isCompletedPayment(byContact)) {
          paymentCompleted = true;
        }
      } catch (e) {
        _log('Payment poll (contact) error: $e');
      }
    }

    return (profilePaid: profilePaid, paymentCompleted: paymentCompleted, paymentFailed: paymentFailed);
  }

  UnlockWaitResult _toWaitResult({
    required bool profilePaid,
    required bool paymentCompleted,
  }) {
    return UnlockWaitResult(
      confirmed: profilePaid,
      paymentCompleted: paymentCompleted && !profilePaid,
    );
  }

  @override
  Future<UnlockWaitResult> checkUnlockStatus({
    required String userId,
    String? email,
    String? phone,
    String? checkoutRequestId,
  }) async {
    _log('--- CHECK UNLOCK STATUS (userId=$userId) ---');
    final status = await _fetchUnlockStatus(
      userId: userId,
      email: email,
      phone: phone,
      checkoutRequestId: checkoutRequestId,
    );
    final result = _toWaitResult(
      profilePaid: status.profilePaid,
      paymentCompleted: status.paymentCompleted,
    );
    _log(
      'Check result -> confirmed=${result.confirmed}, '
          'paymentCompleted=${result.paymentCompleted}',
    );
    return result;
  }

  @override
  Future<UnlockWaitResult> waitForUnlock(
      String userId, {
        String? email,
        String? phone,
        String? checkoutRequestId,
        int maxAttempts = 30,
      }) async {
    _log('--- WAITING FOR UNLOCK (userId=$userId) ---');

    var paymentCompleted = false;
    const maxBonusAttempts = 10;

    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));

      try {
        final status = await _fetchUnlockStatus(
          userId: userId,
          email: email,
          phone: phone,
          checkoutRequestId: checkoutRequestId,
        );

        if (status.profilePaid) {
          _log('Unlock confirmed via profiles.has_paid');
          return _toWaitResult(profilePaid: true, paymentCompleted: false);
        }

        if (status.paymentFailed) {
          _log('Payment failed (Daraja result) on attempt ${i + 1}/$maxAttempts');
          return _toWaitResult(profilePaid: false, paymentCompleted: false);
        }

        if (status.paymentCompleted) {
          paymentCompleted = true;
          _log('Payment completed on attempt ${i + 1}/$maxAttempts — syncing profile');
          break;
        }

        _log('Payment attempt ${i + 1}/$maxAttempts — still pending');
      } catch (e) {
        _log('Polling error: $e');
      }
    }

    if (paymentCompleted) {
      for (var i = 0; i < maxBonusAttempts; i++) {
        await Future<void>.delayed(const Duration(seconds: 3));

        try {
          final status = await _fetchUnlockStatus(
            userId: userId,
            email: email,
            phone: phone,
            checkoutRequestId: checkoutRequestId,
          );

          if (status.profilePaid) {
            _log('Unlock confirmed after profile sync');
            return _toWaitResult(profilePaid: true, paymentCompleted: false);
          }

          _log('Profile sync attempt ${i + 1}/$maxBonusAttempts — has_paid still false');
        } catch (e) {
          _log('Profile sync polling error: $e');
        }
      }
    }

    _log('Unlock NOT confirmed after polling');
    return _toWaitResult(
      profilePaid: false,
      paymentCompleted: paymentCompleted,
    );
  }

  Map<String, dynamic>? _parseJsonResponse(http.Response response) {
    _log('Status code: ${response.statusCode}');
    _log('Raw body: ${response.body}');

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _log('Parsed response: ${jsonEncode(data)}');
      return data;
    } catch (e) {
      _log('Failed to parse JSON: $e');
      return null;
    }
  }

  @override
  Future<void> requestStkPush({
    required String email,
    required String phone,
    required int amount,
  }) async {
    final body = {
      'email': email,
      'phone': phone,
      'amount': amount,
      'purpose': 'account_unlock',
      'user_id': null,
    };

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/public/mpesa/stk',
    );

    _log('--- STK PUSH REQUEST ---');
    _log('URL: $uri');
    _log('Body: ${jsonEncode(body)}');

    http.Response response;
    try {
      response = await _http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      _log('Network error: $e');
      throw AppException('Unable to reach payment server. Check your internet.');
    }

    final data = _parseJsonResponse(response);

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
  Future<String?> initiateStkPush({
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

    _log('--- STK PUSH REQUEST ---');
    _log('URL: $uri');
    _log('Body: ${jsonEncode(body)}');

    http.Response response;
    try {
      response = await _http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      _log('Network error: $e');
      throw AppException('Unable to reach payment server. Check your internet.');
    }

    final data = _parseJsonResponse(response);

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
      return data?['checkoutRequestId']?.toString();
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
      final completed = _isCompletedPayment(payment);
      _log('hasCompletedUnlockPayment -> $payment (completed=$completed)');
      return completed;
    } catch (e) {
      _log('Payment lookup error: $e');
      return false;
    }
  }

  @override
  Future<bool> waitForUnlockByContact({
    required String email,
    required String phone,
    int maxAttempts = 30,
  }) async {
    _log('--- WAITING FOR UNLOCK (email=$email, phone=$phone) ---');

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

        _log('Attempt ${i + 1}/$maxAttempts -> $payment');

        if (_isCompletedPayment(payment)) {
          _log('Payment confirmed');
          return true;
        }
      } catch (e) {
        _log('Polling error: $e');
      }
    }

    _log('Payment NOT confirmed after $maxAttempts attempts');
    return false;
  }
}