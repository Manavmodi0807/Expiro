import 'product_model.dart';

class ProductFilter {
  final String searchQuery;
  final String? category;
  final String? brand;
  final DateTime? purchaseDateFrom;
  final DateTime? purchaseDateTo;
  final WarrantyStatus? warrantyStatus;

  const ProductFilter({
    this.searchQuery = '',
    this.category,
    this.brand,
    this.purchaseDateFrom,
    this.purchaseDateTo,
    this.warrantyStatus,
  });

  bool get isActive =>
      searchQuery.trim().isNotEmpty ||
      category != null ||
      brand != null ||
      purchaseDateFrom != null ||
      purchaseDateTo != null ||
      warrantyStatus != null;

  int get activeFilterCount {
    int count = 0;
    if (category != null && category!.isNotEmpty) count++;
    if (brand != null && brand!.isNotEmpty) count++;
    if (purchaseDateFrom != null || purchaseDateTo != null) count++;
    if (warrantyStatus != null) count++;
    return count;
  }

  ProductFilter copyWith({
    String? searchQuery,
    String? Function()? category,
    String? Function()? brand,
    DateTime? Function()? purchaseDateFrom,
    DateTime? Function()? purchaseDateTo,
    WarrantyStatus? Function()? warrantyStatus,
  }) {
    return ProductFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category != null ? category() : this.category,
      brand: brand != null ? brand() : this.brand,
      purchaseDateFrom: purchaseDateFrom != null ? purchaseDateFrom() : this.purchaseDateFrom,
      purchaseDateTo: purchaseDateTo != null ? purchaseDateTo() : this.purchaseDateTo,
      warrantyStatus: warrantyStatus != null ? warrantyStatus() : this.warrantyStatus,
    );
  }

  bool matches(Product product) {
    // 1. Search Query (Product Name & Brand - case-insensitive, partial matching)
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      final nameMatches = product.productName.toLowerCase().contains(query);
      final brandMatches = product.brand.toLowerCase().contains(query);
      if (!nameMatches && !brandMatches) {
        return false;
      }
    }

    // 2. Category Filter
    if (category != null && category!.trim().isNotEmpty) {
      if (product.category.trim().toLowerCase() != category!.trim().toLowerCase()) {
        return false;
      }
    }

    // 3. Brand Filter
    if (brand != null && brand!.trim().isNotEmpty) {
      if (product.brand.trim().toLowerCase() != brand!.trim().toLowerCase()) {
        return false;
      }
    }

    // 4. Purchase Date Range (Inclusive on day boundaries)
    if (purchaseDateFrom != null) {
      final fromDay = DateTime(
        purchaseDateFrom!.year,
        purchaseDateFrom!.month,
        purchaseDateFrom!.day,
      );
      final productDay = DateTime(
        product.purchaseDate.year,
        product.purchaseDate.month,
        product.purchaseDate.day,
      );
      if (productDay.isBefore(fromDay)) {
        return false;
      }
    }

    if (purchaseDateTo != null) {
      final toDay = DateTime(
        purchaseDateTo!.year,
        purchaseDateTo!.month,
        purchaseDateTo!.day,
      );
      final productDay = DateTime(
        product.purchaseDate.year,
        product.purchaseDate.month,
        product.purchaseDate.day,
      );
      if (productDay.isAfter(toDay)) {
        return false;
      }
    }

    // 5. Warranty Status Filter
    if (warrantyStatus != null) {
      if (product.status != warrantyStatus) {
        return false;
      }
    }

    return true;
  }

  List<Product> apply(List<Product> products) {
    if (!isActive) return products;
    return products.where(matches).toList();
  }
}
