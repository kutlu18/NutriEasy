class AppConfig {
  static const appName = 'NutriEasy';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ifjghwsdpujzopppurdr.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY',
  );

  static const supabaseAuthRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'nutrieasy://reset-password',
  );

  static const demoContentEnabled = bool.fromEnvironment(
    'DEMO_CONTENT_ENABLED',
    defaultValue: false,
  );

  static const photoMealInputEnabled = bool.fromEnvironment(
    'PHOTO_MEAL_INPUT_ENABLED',
    defaultValue: false,
  );

  static const voiceMealInputEnabled = bool.fromEnvironment(
    'VOICE_MEAL_INPUT_ENABLED',
    defaultValue: false,
  );

  static const premiumCheckoutEnabled = bool.fromEnvironment(
    'PREMIUM_CHECKOUT_ENABLED',
    defaultValue: false,
  );

  static const pushNotificationsEnabled = bool.fromEnvironment(
    'PUSH_NOTIFICATIONS_ENABLED',
    defaultValue: false,
  );
}
