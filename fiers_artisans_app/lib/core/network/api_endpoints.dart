class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String registerArtisan = '/auth/register/artisan';
  static const String registerClient = '/auth/register/client';
  static const String refreshToken = '/auth/refresh';
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';

  // Users
  static const String profile = '/users/me';
  static const String updateProfile = '/users/me';
  static String userById(String id) => '/users/$id';

  // Categories
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // Search
  static const String search = '/search/artisans';

  // Reviews
  static const String reviews = '/reviews';
  static String reviewsByArtisan(String artisanId) =>
      '/reviews/artisan/$artisanId';

  // Portfolio
  static const String portfolio = '/portfolio';
  static String portfolioByArtisan(String artisanId) =>
      '/portfolio/artisan/$artisanId';

  // Subscription
  static const String subscription = '/subscription';
  static const String subscriptionStatus = '/subscription/status';

  // Verification
  static const String verification = '/verification';
  static const String verificationSubmit = '/verification/submit';

  // Chat
  static const String conversations = '/chat/conversations';
  static String messages(String conversationId) =>
      '/chat/conversations/$conversationId/messages';

  // Media
  static const String upload = '/media/upload';

  // Notifications
  static const String notifications = '/notifications';

  // Health
  static const String health = '/health';
}
