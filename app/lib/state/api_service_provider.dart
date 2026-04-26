import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart';
import '../services/real_api_service.dart';

/// Toggle between MockApiService and RealApiService.
///
/// Set [_useMockApi] to false when Dev A's backend is ready.
/// The RealApiService uses HMAC-signed requests per COMP_16.
const bool _useMockApi = true; // ← Flip to false for Dev A integration

final apiServiceProvider = Provider<ApiService>((ref) {
  if (_useMockApi) {
    return MockApiService();
  }
  // RealApiService connects to Dev A's backend at the configured base URL.
  // HMAC signing is handled automatically via HmacSigner.
  return RealApiService(baseUrl: 'http://10.0.2.2:8000/api');
});
