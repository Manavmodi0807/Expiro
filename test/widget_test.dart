import 'package:flutter_test/flutter_test.dart';
import 'package:digital_warranty_vault/services/auth_service.dart';

void main() {
  group('AuthService error message tests', () {
    test('Returns default message for unknown error', () {
      final message = AuthService.getReadableErrorMessage(Exception('unknown'));
      expect(message, 'An unexpected error occurred. Please try again.');
    });
  });
}
