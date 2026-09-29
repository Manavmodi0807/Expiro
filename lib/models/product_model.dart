import 'package:cloud_firestore/cloud_firestore.dart';

enum WarrantyStatus {
  active,
  expiringSoon,
  expired,
}

extension WarrantyStatusExtension on WarrantyStatus {
  String get label {
    switch (this) {
      case WarrantyStatus.active:
        return 'Active';
      case WarrantyStatus.expiringSoon:
        return 'Expiring Soon';
      case WarrantyStatus.expired:
        return 'Expired';
    }
  }
}

class Product {
  final String id;
  final String productName;
  final String category;
  final String brand;
  final DateTime purchaseDate;
  final int warrantyDurationMonths;
  final DateTime warrantyExpiryDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const int expiringSoonDaysThreshold = 30;

  static const List<String> defaultCategories = [
    'Electronics',
    'Appliances',
    'Furniture',
    'Automobiles',
    'Computing',
    'Fashion & Accessories',
    'Home & Kitchen',
    'Other',
  ];

  Product({
    required this.id,
    required this.productName,
    required this.category,
    required this.brand,
    required this.purchaseDate,
    required this.warrantyDurationMonths,
    required this.warrantyExpiryDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  WarrantyStatus get status => calculateWarrantyStatus(warrantyExpiryDate);

  static DateTime calculateExpiryDate(DateTime purchaseDate, int durationMonths) {
    final cleanPurchase = DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);
    return DateTime(cleanPurchase.year, cleanPurchase.month + durationMonths, cleanPurchase.day);
  }

  static WarrantyStatus calculateWarrantyStatus(DateTime expiryDate, [DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    if (expiry.isBefore(today)) {
      return WarrantyStatus.expired;
    }

    final differenceInDays = expiry.difference(today).inDays;
    if (differenceInDays <= expiringSoonDaysThreshold) {
      return WarrantyStatus.expiringSoon;
    }

    return WarrantyStatus.active;
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final purchaseDateTime = (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final duration = (data['warrantyDurationMonths'] as num?)?.toInt() ?? 12;
    final expiryDateTime = (data['warrantyExpiryDate'] as Timestamp?)?.toDate() ??
        calculateExpiryDate(purchaseDateTime, duration);

    return Product(
      id: doc.id,
      productName: data['productName'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      brand: data['brand'] as String? ?? '',
      purchaseDate: purchaseDateTime,
      warrantyDurationMonths: duration,
      warrantyExpiryDate: expiryDateTime,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isNew = false}) {
    final map = <String, dynamic>{
      'productName': productName,
      'category': category,
      'brand': brand,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'warrantyDurationMonths': warrantyDurationMonths,
      'warrantyExpiryDate': Timestamp.fromDate(warrantyExpiryDate),
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  Product copyWith({
    String? id,
    String? productName,
    String? category,
    String? brand,
    DateTime? purchaseDate,
    int? warrantyDurationMonths,
    DateTime? warrantyExpiryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyDurationMonths: warrantyDurationMonths ?? this.warrantyDurationMonths,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
