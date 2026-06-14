abstract class PaymentRepository {
  Future<void> initiateStkPush({
    required String email,
    required String phone,
    required int amount,
    required String purpose,
    String? userId,
    String? bookingId,
  });

  Future<bool> waitForUnlock(String userId, {int maxAttempts = 30});

  /// Polls for payment confirmation by email/phone, for use when the
  /// user has no account yet (pre-signup unlock flow).
  Future<bool> waitForUnlockByContact({
    required String email,
    required String phone,
    int maxAttempts = 30,
  });

  /// Returns true if a completed account_unlock payment exists for the contact.
  Future<bool> hasCompletedUnlockPayment({
    required String email,
    required String phone,
  });

  Future<void> requestStkPush({required String email, required String phone, required int amount}) async {}
}