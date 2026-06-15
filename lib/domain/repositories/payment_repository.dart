/// Result of polling after an STK push for account unlock.
class UnlockWaitResult {
  const UnlockWaitResult({
    required this.confirmed,
    this.paymentCompleted = false,
  });

  /// `profiles.has_paid` is true — user can access premium content.
  final bool confirmed;

  /// A completed `account_unlock` payment exists but profile may still be syncing.
  final bool paymentCompleted;
}

abstract class PaymentRepository {
  Future<void> initiateStkPush({
    required String email,
    required String phone,
    required int amount,
    required String purpose,
    String? userId,
    String? bookingId,
  });

  Future<UnlockWaitResult> waitForUnlock(
    String userId, {
    String? email,
    String? phone,
    int maxAttempts = 30,
  });

  /// One-shot status check (no initial delay) — for manual "Check again".
  Future<UnlockWaitResult> checkUnlockStatus({
    required String userId,
    String? email,
    String? phone,
  });

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