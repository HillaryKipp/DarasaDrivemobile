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
}
