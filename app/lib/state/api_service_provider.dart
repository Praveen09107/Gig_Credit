import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/real_api_service.dart';

// Force RealApiService to ensure no mock usage in production.
final apiServiceProvider = Provider<ApiService>((ref) {
  return RealApiService();
});
