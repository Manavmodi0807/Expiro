import 'package:flutter_test/flutter_test.dart';
import 'package:digital_warranty_vault/models/product_document_model.dart';
import 'package:digital_warranty_vault/models/product_model.dart';
import 'package:digital_warranty_vault/services/auth_service.dart';
import 'package:digital_warranty_vault/services/document_service.dart';

void main() {
  group('AuthService error message tests', () {
    test('Returns default message for unknown error', () {
      final message = AuthService.getReadableErrorMessage(Exception('unknown'));
      expect(message, 'An unexpected error occurred. Please try again.');
    });
  });

  group('Warranty Calculation Tests', () {
    test('calculateExpiryDate correctly calculates standard duration', () {
      final purchase = DateTime(2026, 1, 15);
      final expiry = Product.calculateExpiryDate(purchase, 12);
      expect(expiry, DateTime(2027, 1, 15));
    });

    test('calculateExpiryDate handles multi-year duration', () {
      final purchase = DateTime(2026, 5, 20);
      final expiry = Product.calculateExpiryDate(purchase, 36);
      expect(expiry, DateTime(2029, 5, 20));
    });

    test('calculateExpiryDate handles partial year duration', () {
      final purchase = DateTime(2026, 3, 10);
      final expiry = Product.calculateExpiryDate(purchase, 6);
      expect(expiry, DateTime(2026, 9, 10));
    });
  });

  group('Warranty Status Determination Tests', () {
    test('Returns expired when expiry date is before reference today', () {
      final referenceToday = DateTime(2026, 9, 29);
      final pastExpiry = DateTime(2026, 9, 20);
      final status = Product.calculateWarrantyStatus(pastExpiry, referenceToday);
      expect(status, WarrantyStatus.expired);
      expect(status.label, 'Expired');
    });

    test('Returns expiring soon when expiry is within 30 days', () {
      final referenceToday = DateTime(2026, 9, 29);
      final soonExpiry = DateTime(2026, 10, 15); // 16 days away <= 30
      final status = Product.calculateWarrantyStatus(soonExpiry, referenceToday);
      expect(status, WarrantyStatus.expiringSoon);
      expect(status.label, 'Expiring Soon');
    });

    test('Returns active when expiry is more than 30 days away', () {
      final referenceToday = DateTime(2026, 9, 29);
      final futureExpiry = DateTime(2027, 9, 29); // 1 year away
      final status = Product.calculateWarrantyStatus(futureExpiry, referenceToday);
      expect(status, WarrantyStatus.active);
      expect(status.label, 'Active');
    });
  });

  group('ProductDocument Model Tests', () {
    test('Correctly identifies PDF document', () {
      final doc = ProductDocument(
        id: 'doc_1',
        fileName: 'invoice.pdf',
        documentType: 'Bill / Invoice',
        storagePath: 'users/u1/products/p1/documents/doc_1',
        downloadUrl: 'https://example.com/invoice.pdf',
        contentType: 'application/pdf',
        fileSizeBytes: 102400,
      );

      expect(doc.isPdf, isTrue);
      expect(doc.isImage, isFalse);
    });

    test('Correctly identifies Image document', () {
      final doc = ProductDocument(
        id: 'doc_2',
        fileName: 'receipt.jpg',
        documentType: 'Purchase Receipt',
        storagePath: 'users/u1/products/p1/documents/doc_2',
        downloadUrl: 'https://example.com/receipt.jpg',
        contentType: 'image/jpeg',
        fileSizeBytes: 204800,
      );

      expect(doc.isImage, isTrue);
      expect(doc.isPdf, isFalse);
    });

    test('DocumentService error handler translates codes safely', () {
      final msg = DocumentService.getReadableErrorMessage(Exception('generic'));
      expect(msg, contains('Exception'));
    });
  });
}
