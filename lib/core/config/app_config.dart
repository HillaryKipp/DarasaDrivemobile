/// Shared backend configuration — same Supabase project as the web app.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = 'https://ubsntnfkeilralsxqaus.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVic250bmZrZWlscmFsc3hxYXVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwMDMwODUsImV4cCI6MjA5NjU3OTA4NX0.apuMQ0GApL7xKwbxrvdlyFsuaZfXwV7-dAdvnDOoLtk';

  /// Stable published URL for M-Pesa STK Push (not preview URLs).
  static const apiBaseUrl =
      'https://project--bb500606-2c15-4a45-8b76-5b135f0ce600.lovable.app';

  static const unlockAmountKes = 1;
  static const unlockPurpose = 'account_unlock';
  static const bookingPurpose = 'booking';
}
