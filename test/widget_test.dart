import 'package:flutter_test/flutter_test.dart';
import 'package:digital_warranty_vault/models/product_document_model.dart';
import 'package:digital_warranty_vault/models/product_filter_model.dart';
import 'package:digital_warranty_vault/models/product_model.dart';
import 'package:digital_warranty_vault/services/auth_service.dart';
import 'package:digital_warranty_vault/services/document_service.dart';
import 'package:digital_warranty_vault/services/notification_service.dart';
import 'package:digital_warranty_vault/services/ocr_service.dart';

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

  group('NotificationService & Reminder Tests', () {
    final expiryDate = DateTime(2026, 12, 31);

    test('30-day reminder date calculation is exact', () {
      final reminder = NotificationService.calculateReminderDateTime(expiryDate, 30);
      expect(reminder.year, 2026);
      expect(reminder.month, 12);
      expect(reminder.day, 1);
      expect(reminder.hour, 9);
      expect(reminder.minute, 0);
    });

    test('15-day reminder date calculation is exact', () {
      final reminder = NotificationService.calculateReminderDateTime(expiryDate, 15);
      expect(reminder.year, 2026);
      expect(reminder.month, 12);
      expect(reminder.day, 16);
      expect(reminder.hour, 9);
      expect(reminder.minute, 0);
    });

    test('7-day reminder date calculation is exact', () {
      final reminder = NotificationService.calculateReminderDateTime(expiryDate, 7);
      expect(reminder.year, 2026);
      expect(reminder.month, 12);
      expect(reminder.day, 24);
      expect(reminder.hour, 9);
      expect(reminder.minute, 0);
    });

    test('Future reminder is approved for scheduling', () {
      final referenceNow = DateTime(2026, 10, 1, 8, 0);
      final reminderTime = NotificationService.calculateReminderDateTime(expiryDate, 30); // 2026-12-01
      final shouldSchedule = NotificationService.shouldScheduleReminder(
        reminderDateTime: reminderTime,
        referenceNow: referenceNow,
        expiryDate: expiryDate,
      );
      expect(shouldSchedule, isTrue);
    });

    test('Past reminder is not scheduled', () {
      final referenceNow = DateTime(2026, 12, 10, 10, 0);
      final reminderTime = NotificationService.calculateReminderDateTime(expiryDate, 30); // 2026-12-01 (in the past)
      final shouldSchedule = NotificationService.shouldScheduleReminder(
        reminderDateTime: reminderTime,
        referenceNow: referenceNow,
        expiryDate: expiryDate,
      );
      expect(shouldSchedule, isFalse);
    });

    test('Expired warranty does not schedule reminders', () {
      final pastExpiry = DateTime(2026, 5, 1);
      final referenceNow = DateTime(2026, 10, 1);
      final reminderTime = NotificationService.calculateReminderDateTime(pastExpiry, 7);
      final shouldSchedule = NotificationService.shouldScheduleReminder(
        reminderDateTime: reminderTime,
        referenceNow: referenceNow,
        expiryDate: pastExpiry,
      );
      expect(shouldSchedule, isFalse);
    });

    test('Notification ID generation is deterministic and non-negative', () {
      final id1 = NotificationService.generateNotificationId('prod_123', 30);
      final id2 = NotificationService.generateNotificationId('prod_123', 30);
      expect(id1, id2);
      expect(id1 >= 0, isTrue);
    });

    test('Different products and reminder intervals generate distinct notification IDs', () {
      final id30 = NotificationService.generateNotificationId('prod_123', 30);
      final id15 = NotificationService.generateNotificationId('prod_123', 15);
      final idOtherProduct = NotificationService.generateNotificationId('prod_456', 30);

      expect(id30, isNot(equals(id15)));
      expect(id30, isNot(equals(idOtherProduct)));
    });
  });

  group('OcrService & Parsing Tests', () {
    test('Empty text returns empty candidate fields', () {
      final fields = OcrService.extractCandidateFields('');
      expect(fields.hasAnyField, isFalse);
      expect(fields.productName, isNull);
      expect(fields.brand, isNull);
      expect(fields.purchaseDate, isNull);
      expect(fields.warrantyDurationMonths, isNull);
    });

    test('Extracts labeled product name and brand', () {
      const sampleText = '''
INVOICE #1042
Product Name: Sony WH-1000XM5
Brand: Sony
Date: 2026-05-15
Warranty Period: 2 years
''';
      final fields = OcrService.extractCandidateFields(sampleText);
      expect(fields.productName, 'Sony WH-1000XM5');
      expect(fields.brand, 'Sony');
      expect(fields.purchaseDate, DateTime(2026, 5, 15));
      expect(fields.warrantyDurationMonths, 24);
      expect(fields.hasAnyField, isTrue);
    });

    test('Extracts DD/MM/YYYY date and month duration', () {
      const sampleText = '''
RETAIL RECEIPT
Item: Dell XPS 15
Manufacturer: Dell
Purchase Date: 12/04/2026
Warranty: 12 months
''';
      final fields = OcrService.extractCandidateFields(sampleText);
      expect(fields.productName, 'Dell XPS 15');
      expect(fields.brand, 'Dell');
      expect(fields.purchaseDate, DateTime(2026, 4, 12));
      expect(fields.warrantyDurationMonths, 12);
    });

    test('Extracts partial/unlabeled fields safely without guessing', () {
      const sampleText = '''
STORE CASH MEMO
Some random text
Invoice date 2026/08/20
Thank you for shopping!
''';
      final fields = OcrService.extractCandidateFields(sampleText);
      expect(fields.productName, isNull);
      expect(fields.brand, isNull);
      expect(fields.purchaseDate, DateTime(2026, 8, 20));
      expect(fields.warrantyDurationMonths, isNull);
    });

    test('OcrService error translator returns readable user messages', () {
      final msg1 = OcrService.getReadableErrorMessage(const OcrException('Custom error'));
      expect(msg1, 'Custom error');

      final msg2 = OcrService.getReadableErrorMessage(Exception('File does not exist'));
      expect(msg2, 'Selected document image file could not be found.');

      final msg3 = OcrService.getReadableErrorMessage(Exception('Unknown OCR error'));
      expect(msg3, 'Unable to read this document. Please try a clearer image.');
    });
  });
}

