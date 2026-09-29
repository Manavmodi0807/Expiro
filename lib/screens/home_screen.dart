import 'package:flutter/material.dart';
import '../models/product_filter_model.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import 'documents/product_documents_screen.dart';
import 'products/product_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _productService = ProductService();
  final _searchController = TextEditingController();

  ProductFilter _filter = const ProductFilter();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_filter.searchQuery != _searchController.text) {
      setState(() {
        _filter = _filter.copyWith(searchQuery: _searchController.text);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getStatusColor(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.active:
        return Colors.green.shade700;
      case WarrantyStatus.expiringSoon:
        return Colors.orange.shade800;
      case WarrantyStatus.expired:
        return Colors.red.shade700;
    }
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _filter = const ProductFilter();
    });
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.productName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _productService.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = ProductService.getReadableErrorMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your vault?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
    }
  }

  void _openDocuments(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDocumentsScreen(product: product),
      ),
    );
  }

  Future<void> _openFilterModal(List<Product> allProducts) async {
    // Collect available unique categories
    final productCategories = allProducts
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty);
    final categorySet = <String>{...Product.defaultCategories, ...productCategories};
    final categories = categorySet.toList()..sort();

    // Collect available unique brands
    final brandSet = allProducts
        .map((p) => p.brand.trim())
        .where((b) => b.isNotEmpty)
        .toSet();
    final brands = brandSet.toList()..sort();

    // Temporary local filter state in modal
    String? tempCategory = _filter.category;
    String? tempBrand = _filter.brand;
    DateTime? tempFrom = _filter.purchaseDateFrom;
    DateTime? tempTo = _filter.purchaseDateTo;
    WarrantyStatus? tempStatus = _filter.warrantyStatus;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tune_rounded, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Filter Products',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempCategory = null;
                                tempBrand = null;
                                tempFrom = null;
                                tempTo = null;
                                tempStatus = null;
                              });
                            },
                            child: const Text('Reset All'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Warranty Status Filter
                      Text(
                        'Warranty Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: tempStatus == null,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => tempStatus = null);
                              }
                            },
                          ),
                          ...WarrantyStatus.values.map((status) {
                            return ChoiceChip(
                              label: Text(status.label),
                              selected: tempStatus == status,
                              onSelected: (selected) {
                                setModalState(() {
                                  tempStatus = selected ? status : null;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Category Filter
                      Text(
                        'Category',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: tempCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'All Categories',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map((c) => DropdownMenuItem<String?>(
                                value: c,
                                child: Text(c),
                              )),
                        ],
                        onChanged: (val) {
                          setModalState(() => tempCategory = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // Brand Filter
                      Text(
                        'Brand',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: tempBrand,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: brands.isEmpty ? 'No brands recorded' : 'All Brands',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Brands'),
                          ),
                          ...brands.map((b) => DropdownMenuItem<String?>(
                                value: b,
                                child: Text(b),
                              )),
                        ],
                        onChanged: brands.isEmpty
                            ? null
                            : (val) {
                                setModalState(() => tempBrand = val);
                              },
                      ),
                      const SizedBox(height: 18),

                      // Purchase Date Range Filter
                      Text(
                        'Purchase Date Range',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // From Date
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: tempFrom ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() => tempFrom = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_outlined, size: 16),
                              label: Text(
                                tempFrom != null ? _formatDate(tempFrom!) : 'From Date',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (tempFrom != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Clear From Date',
                              onPressed: () => setModalState(() => tempFrom = null),
                            ),
                          const SizedBox(width: 8),
                          // To Date
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: tempTo ?? tempFrom ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() => tempTo = picked);
                                }
                              },
                              icon: const Icon(Icons.event_outlined, size: 16),
                              label: Text(
                                tempTo != null ? _formatDate(tempTo!) : 'To Date',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (tempTo != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Clear To Date',
                              onPressed: () => setModalState(() => tempTo = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _filter = _filter.copyWith(
                                    category: () => tempCategory,
                                    brand: () => tempBrand,
                                    purchaseDateFrom: () => tempFrom,
                                    purchaseDateTo: () => tempTo,
                                    warrantyStatus: () => tempStatus,
                                  );
                                });
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Digital Warranty Vault',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Product>>(
          stream: _productService.getProductsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load dashboard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ProductService.getReadableErrorMessage(snapshot.error),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final products = snapshot.data ?? [];

            if (products.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Products in Vault',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep your product warranties organized and tracked in one secure place.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProductFormScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Product'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Products exist in vault. Apply search and filters:
            final filteredProducts = _filter.apply(products);

            final activeProducts = products
                .where((p) => p.status == WarrantyStatus.active)
                .toList();

            final expiringProducts = products
                .where((p) => p.status == WarrantyStatus.expiringSoon)
                .toList();

            final expiredProducts = products
                .where((p) => p.status == WarrantyStatus.expired)
                .toList();

            // Recent products ordered by creation date descending
            final recentProducts = List<Product>.from(products)
              ..sort((a, b) {
                final dateA = a.createdAt ?? a.purchaseDate;
                final dateB = b.createdAt ?? b.purchaseDate;
                return dateB.compareTo(dateA);
              });

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Filter Bar
                  _buildSearchAndFilterBar(products, theme, colorScheme),
                  const SizedBox(height: 12),

                  // Active Filter Chips
                  if (_filter.isActive) ...[
                    _buildActiveFilterChips(theme, colorScheme),
                    const SizedBox(height: 16),
                  ],

                  // If search/filter is active, show the filtered list
                  if (_filter.isActive) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtered Results (${filteredProducts.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _resetAllFilters,
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (filteredProducts.isEmpty)
                      _buildNoFilterResultsCard(theme, colorScheme)
                    else
                      ...filteredProducts.map((p) => _buildProductCard(p, theme, colorScheme)),
                  ] else ...[
                    // Default Dashboard View
                    _buildSummaryMetrics(
                      total: products.length,
                      active: activeProducts.length,
                      expiring: expiringProducts.length,
                      expired: expiredProducts.length,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 24),

                    // EXPIRING SOON SECTION
                    _buildSectionHeader(
                      title: 'Expiring Soon',
                      count: expiringProducts.length,
                      icon: Icons.notification_important_rounded,
                      iconColor: Colors.orange.shade800,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    if (expiringProducts.isEmpty)
                      _buildEmptySectionCard(
                        message: 'No products expiring soon',
                        icon: Icons.check_circle_outline_rounded,
                        theme: theme,
                        colorScheme: colorScheme,
                      )
                    else
                      ...expiringProducts.map((p) => _buildProductCard(p, theme, colorScheme)),

                    const SizedBox(height: 24),

                    // ACTIVE PRODUCTS SECTION
                    _buildSectionHeader(
                      title: 'Active Products',
                      count: activeProducts.length,
                      icon: Icons.verified_user_rounded,
                      iconColor: Colors.green.shade700,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    if (activeProducts.isEmpty)
                      _buildEmptySectionCard(
                        message: 'No active warranties',
                        icon: Icons.hourglass_empty_rounded,
                        theme: theme,
                        colorScheme: colorScheme,
                      )
                    else
                      ...activeProducts.map((p) => _buildProductCard(p, theme, colorScheme)),

                    const SizedBox(height: 24),

                    // RECENT PRODUCTS SECTION
                    _buildSectionHeader(
                      title: 'Recent Products',
                      count: recentProducts.length,
                      icon: Icons.history_rounded,
                      iconColor: colorScheme.primary,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    if (recentProducts.isEmpty)
                      _buildEmptySectionCard(
                        message: 'No recent products',
                        icon: Icons.inbox_outlined,
                        theme: theme,
                        colorScheme: colorScheme,
                      )
                    else
                      ...recentProducts
                          .take(5)
                          .map((p) => _buildProductCard(p, theme, colorScheme)),
                  ],

                  const SizedBox(height: 80), // Padding for floating action button
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
        },
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
    List<Product> products,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final filterCount = _filter.activeFilterCount;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or brand...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          child: IconButton.filledTonal(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter Products',
            onPressed: () => _openFilterModal(products),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_filter.searchQuery.trim().isNotEmpty)
          Chip(
            avatar: const Icon(Icons.search, size: 16),
            label: Text('"${_filter.searchQuery.trim()}"'),
            onDeleted: () => _searchController.clear(),
            deleteIconColor: colorScheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.warrantyStatus != null)
          Chip(
            avatar: const Icon(Icons.shield_outlined, size: 16),
            label: Text(_filter.warrantyStatus!.label),
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(warrantyStatus: () => null);
              });
            },
            deleteIconColor: colorScheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.category != null)
          Chip(
            avatar: const Icon(Icons.category_outlined, size: 16),
            label: Text(_filter.category!),
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(category: () => null);
              });
            },
            deleteIconColor: colorScheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.brand != null)
          Chip(
            avatar: const Icon(Icons.branding_watermark_outlined, size: 16),
            label: Text(_filter.brand!),
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(brand: () => null);
              });
            },
            deleteIconColor: colorScheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.purchaseDateFrom != null || _filter.purchaseDateTo != null)
          Chip(
            avatar: const Icon(Icons.date_range_outlined, size: 16),
            label: Text(
              _filter.purchaseDateFrom != null && _filter.purchaseDateTo != null
                  ? '${_formatDate(_filter.purchaseDateFrom!)} - ${_formatDate(_filter.purchaseDateTo!)}'
                  : _filter.purchaseDateFrom != null
                      ? 'From ${_formatDate(_filter.purchaseDateFrom!)}'
                      : 'To ${_formatDate(_filter.purchaseDateTo!)}',
            ),
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(
                  purchaseDateFrom: () => null,
                  purchaseDateTo: () => null,
                );
              });
            },
            deleteIconColor: colorScheme.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildNoFilterResultsCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No products match your filters',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting or resetting your search and filter criteria.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _resetAllFilters,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics({
    required int total,
    required int active,
    required int expiring,
    required int expired,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Active',
            count: active,
            color: Colors.green.shade700,
            bgColor: Colors.green.shade50,
            icon: Icons.verified_user_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Expiring',
            count: expiring,
            color: Colors.orange.shade800,
            bgColor: Colors.orange.shade50,
            icon: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            label: 'Expired',
            count: expired,
            color: Colors.red.shade700,
            bgColor: Colors.red.shade50,
            icon: Icons.history_toggle_off_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySectionCard({
    required String message,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final status = product.status;
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDocuments(product),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Product Name & Popup Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.brand.isNotEmpty
                              ? '${product.brand} • ${product.category}'
                              : product.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Product Options',
                    onSelected: (value) {
                      if (value == 'docs') {
                        _openDocuments(product);
                      } else if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductFormScreen(
                              productToEdit: product,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(product);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'docs',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Documents / Bills'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),

              // Dates & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchased: ${_formatDate(product.purchaseDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Expires: ${_formatDate(product.warrantyExpiryDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              // Optional notes
              if (product.notes != null && product.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${product.notes}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
