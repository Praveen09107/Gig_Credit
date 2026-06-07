import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://gig-credit.onrender.com';
  static String get apiKey => dotenv.env['API_KEY'] ?? 'gigcredit-demo-api-key-2026';
  
  static String get twilioAccountSid => dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
  static String get twilioAuthToken => dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
  static String get twilioServiceSid => dotenv.env['TWILIO_SERVICE_SID'] ?? '';
}
