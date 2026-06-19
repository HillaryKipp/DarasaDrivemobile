/// Shared backend configuration — same Supabase project as the web app.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = 'https://ubsntnfkeilralsxqaus.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVic250bmZrZWlscmFsc3hxYXVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwMDMwODUsImV4cCI6MjA5NjU3OTA4NX0.apuMQ0GApL7xKwbxrvdlyFsuaZfXwV7-dAdvnDOoLtk';

  /// Stable published URL for M-Pesa STK Push (not preview URLs).
  static const apiBaseUrl =
      'https://project--bb500606-2c15-4a45-8b76-5b135f0ce600.lovable.app';

  static const unlockAmountKes = 500;
  static const unlockPurpose = 'account_unlock';
  static const bookingPurpose = 'booking';

  /// Google Play Billing Product IDs
  static const iapUnlockProductId = 'account_unlock';

  /// Base64-encoded RSA public key from Google Play Console (Monetization setup)
  static const googlePlayPublicKey = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhjYY7xPOTWNMhBkjtKwBtrLdQfauhzcaOv753MB1QOkmqAqpK1SKOoB6bWUsEGvufPpwFbhvLuA4/czfwTTgmrjgv1gjMqd+2PYyzBNZxyGzWy8o98xcUcUwTOYmdxe8g1zaVv0tMQXtmBcOqvmrMZJtQ6yhItGEHYr0rcnhbd/fzNNEN+hEq3FpVMo0lXXBT1IT+TBEnuQFe2b0t7HuCvQU+HxLCu4Vt3LCrEJ/BDRoYF5/OmZqNHIPfJuk6+1degx/p9i0aG0/tjP17qG+UBhyZzkhS7m5VzX4RWEfF8eUM7tI3MZoanHGAI3K86ZGRg870WJ62B63LihEbG7j5wIDAQAB';
}
