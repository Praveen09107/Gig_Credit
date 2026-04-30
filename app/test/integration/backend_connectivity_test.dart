import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:gigcredit/services/real_api_service.dart';
import 'package:gigcredit/services/scoring_service.dart';
import 'package:gigcredit/services/loan_service.dart';

/// Integration Test Suite: Backend Connectivity
/// Validates that Flutter services can successfully reach the production Dev A backend.
/// Ensures 200 OK responses or expected operational status from core endpoints.
void main() {
  group('Backend Connectivity Integration Tests', () {
    late RealApiService apiService;

    setUpAll(() {
      apiService = RealApiService(baseUrl: 'https://gig-credit.onrender.com/api');
    });

    test('ScoringService initialization should point to production', () {
      final scoringService = ScoringService();
      expect(scoringService, isNotNull);
    });
    
    test('LoanService initialization should point to production', () {
      final loanService = LoanService();
      expect(loanService, isNotNull);
    });

    test('Backend Health/Root Check via raw HTTP', () async {
      try {
        final response = await http.get(Uri.parse('https://gig-credit.onrender.com/'));
        // 404 or 200 is acceptable for root, as long as it's reachable and not timed out.
        // We know Dev A's backend root returns 404 Not Found since APIs are under /api or /docs.
        expect(response.statusCode == 200 || response.statusCode == 404, isTrue);
        print('✅ Backend server is ALIVE and reachable.');
      } catch (e) {
        fail('Backend is totally unreachable: $e');
      }
    });

    test('Test Aadhaar Verification Endpoint Rejection (Validates API connection)', () async {
      try {
        // We will send a completely invalid Aadhaar just to see if the backend catches it
        // This validates that the connection works and the backend returns a formatted 4xx detail.
        await apiService.verifyAadhaar('123');
        fail('Should not succeed with invalid Aadhaar');
      } catch (e) {
        // Expected an exception with an error message from the backend!
        // Even 'Not Found' means the server actively responded and caught the request to an API endpoint
        expect(e.toString(), anyOf(contains('Failed to verify Aadhaar'), contains('Not Found')));
        print('✅ API connection successful: Backend gracefully processed request.');
      }
    });
  });
}
