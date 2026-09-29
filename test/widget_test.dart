import 'package:flutter_test/flutter_test.dart';
import 'package:digital_warranty_vault/models/product_document_model.dart';
import 'package:digital_warranty_vault/models/product_filter_model.dart';
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

  group('ProductFilter Model & Search Tests', () {
    final sampleProducts = [
      Product(
        id: 'p1',
        productName: 'Samsung Galaxy S24',
        category: 'Electronics',
        brand: 'Samsung',
        purchaseDate: DateTime(2026, 1, 10),
        warrantyDurationMonths: 24,
        warrantyExpiryDate: DateTime(2028, 1, 10),
      ),
      Product(
        id: 'p2',
        productName: 'MacBook Pro M3',
        category: 'Computing',
        brand: 'Apple',
        purchaseDate: DateTime(2025, 10, 5),
        warrantyDurationMonths: 12,
        warrantyExpiryDate: DateTime(2026, 10, 5), // Expiring soon relative to late Sept 2026
      ),
      Product(
        id: 'p3',
        productName: 'LG Smart Refrigerator',
        category: 'Appliances',
        brand: 'LG',
        purchaseDate: DateTime(2024, 1, 15),
        warrantyDurationMonths: 12,
        warrantyExpiryDate: DateTime(2025, 1, 15), // Expired
      ),
    ];

    test('Inactive filter returns all products', () {
      const filter = ProductFilter();
      expect(filter.isActive, isFalse);
      expect(filter.activeFilterCount, 0);
      final results = filter.apply(sampleProducts);
      expect(results.length, 3);
    });

    test('Search by product name matches case-insensitively and partially', () {
      const filter = ProductFilter(searchQuery: 'galaxy');
      expect(filter.isActive, isTrue);
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.productName, 'Samsung Galaxy S24');
    });

    test('Search by brand matches correctly', () {
      const filter = ProductFilter(searchQuery: 'app');
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.brand, 'Apple');
    });

    test('Filter by Category works', () {
      const filter = ProductFilter(category: 'Appliances');
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.id, 'p3');
    });

    test('Filter by Brand works', () {
      const filter = ProductFilter(brand: 'Samsung');
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.id, 'p1');
    });

    test('Filter by Purchase Date range (inclusive) works', () {
      final filter = ProductFilter(
        purchaseDateFrom: DateTime(2025, 1, 1),
        purchaseDateTo: DateTime(2025, 12, 31),
      );
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.id, 'p2');
    });

    test('Filter by Purchase Date From only works', () {
      final filter = ProductFilter(
        purchaseDateFrom: DateTime(2026, 1, 1),
      );
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.id, 'p1');
    });

    test('Filter by Purchase Date To only works', () {
      final filter = ProductFilter(
        purchaseDateTo: DateTime(2024, 12, 31),
      );
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.id, 'p3');
    });

    test('Filter by Warranty Status works', () {
      const filter = ProductFilter(warrantyStatus: WarrantyStatus.expired);
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.id, 'p3');
    });

    test('Combined filters work together', () {
      final filter = ProductFilter(
        searchQuery: 'samsung',
        category: 'Electronics',
        brand: 'Samsung',
        warrantyStatus: WarrantyStatus.active,
        purchaseDateFrom: DateTime(2026, 1, 1),
      );
      expect(filter.activeFilterCount, 4);
      final results = filter.apply(sampleProducts);
      expect(results.length, 1);
      expect(results.first.id, 'p1');
    });

    test('Combined filters return empty list when no product matches all criteria', () {
      const filter = ProductFilter(
        searchQuery: 'samsung',
        category: 'Appliances', // Mismatched category for Samsung Galaxy S24
      );
      final results = filter.apply(sampleProducts);
      expect(results.isEmpty, isTrue);
    });
  });
}
