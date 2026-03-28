class AppConfig {
  static const String appName = 'Fiers Artisans';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String wsBaseUrl = 'ws://10.0.2.2:3000';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // OTP
  static const int otpLength = 6;
  static const int otpResendDelay = 60; // seconds

  // Search
  static const double defaultSearchRadius = 10.0; // km
  static const double maxSearchRadius = 50.0; // km

  // Pagination
  static const int defaultPageSize = 20;

  // Subscription
  static const int subscriptionAmountFCFA = 5000;

  // Cache
  static const Duration imageCacheDuration = Duration(days: 7);

  // Côte d'Ivoire phone prefix
  static const String phonePrefix = '+225';
}
