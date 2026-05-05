class AppConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://gig-credit.onrender.com');
  static const String apiKey = String.fromEnvironment('API_KEY', defaultValue: 'gigcredit-demo-api-key-2026');
}
