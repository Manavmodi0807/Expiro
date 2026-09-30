import 'package:flutter/material.dart';
import '../models/product_filter_model.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/status_badge.dart';
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
        icon: const Icon(Icons.delete_outline_rounded, size: 40, color: Color(0xFFDC2626)),
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.productName}" from your vault? This action cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
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
        await NotificationService().cancelProductReminders(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Product deleted successfully from vault.'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        icon: const Icon(Icons.logout_rounded, size: 36, color: AppTheme.primary),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Digital Warranty Vault?'),
        actions: [
          OutlinedButton(
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
    final productCategories = allProducts
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty);
    final categorySet = <String>{...Product.defaultCategories, ...productCategories};
    final categories = categorySet.toList()..sort();

    final brandSet = allProducts
        .map((p) => p.brand.trim())
        .where((b) => b.isNotEmpty)
        .toSet();
    final brands = brandSet.toList()..sort();

    String? tempCategory = _filter.category;
    String? tempBrand = _filter.brand;
    DateTime? tempFrom = _filter.purchaseDateFrom;
    DateTime? tempTo = _filter.purchaseDateTo;
    WarrantyStatus? tempStatus = _filter.warrantyStatus;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 8.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, color: AppTheme.primary, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Filter Vault Products',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
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
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Warranty Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All Statuses'),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: tempCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'All Categories',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Brand',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: tempBrand,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: brands.isEmpty ? 'No brands recorded' : 'All Brands',
                          prefixIcon: const Icon(Icons.branding_watermark_outlined, size: 20),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Purchase Date Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
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
                                style: const TextStyle(fontSize: 12.5),
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
                                style: const TextStyle(fontSize: 12.5),
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
                      const SizedBox(height: 28),
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

  Widget _buildSearchAndFilterBar(List<Product> products) {
    final filterCount = _filter.activeFilterCount;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products or brands...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textSecondary),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.primary,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openFilterModal(products),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: filterCount > 0 ? AppTheme.primary : AppTheme.borderLight,
                    width: filterCount > 0 ? 1.5 : 1,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: filterCount > 0 ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_filter.searchQuery.trim().isNotEmpty)
          Chip(
            avatar: const Icon(Icons.search, size: 14, color: AppTheme.primary),
            label: Text('"${_filter.searchQuery.trim()}"'),
            onDeleted: () => _searchController.clear(),
            deleteIconColor: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.warrantyStatus != null)
          Chip(
            avatar: Icon(
              AppTheme.getStatusIcon(_filter.warrantyStatus!),
              size: 14,
              color: AppTheme.getStatusTextColor(_filter.warrantyStatus!),
            ),
            label: Text(_filter.warrantyStatus!.label),
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(warrantyStatus: () => null);
              });
            },
            deleteIconColor: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.category != null)
          Chip(
            avatar: Icon(
              AppTheme.getCategoryIcon(_filter.category!),
              size: 14,
              color: AppTheme.primary,
            ),
            label: Text(_filter.category!),
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(category: () => null);
              });
            },
            deleteIconColor: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.brand != null)
          Chip(
            avatar: const Icon(Icons.branding_watermark_outlined, size: 14, color: AppTheme.primary),
            label: Text(_filter.brand!),
            onDeleted: () {
              setState(() {
                _filter = _filter.copyWith(brand: () => null);
              });
            },
            deleteIconColor: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        if (_filter.purchaseDateFrom != null || _filter.purchaseDateTo != null)
          Chip(
            avatar: const Icon(Icons.date_range_outlined, size: 14, color: AppTheme.primary),
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
            deleteIconColor: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildNoFilterResultsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_alt_off_rounded,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No matching products found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting or resetting your search query or filter options.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _resetAllFilters,
            icon: const Icon(Icons.refresh_rounded, size: 18),
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
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Active',
            count: active,
            icon: Icons.verified_user_rounded,
            textColor: AppTheme.statusActiveText,
            bgColor: AppTheme.statusActiveBg,
            borderColor: AppTheme.statusActiveBorder,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Expiring',
            count: expiring,
            icon: Icons.warning_amber_rounded,
            textColor: AppTheme.statusExpiringText,
            bgColor: AppTheme.statusExpiringBg,
            borderColor: AppTheme.statusExpiringBorder,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Expired',
            count: expired,
            icon: Icons.event_busy_rounded,
            textColor: AppTheme.statusExpiredText,
            bgColor: AppTheme.statusExpiredBg,
            borderColor: AppTheme.statusExpiredBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required IconData icon,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
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
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySectionCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final status = product.status;
    final categoryIcon = AppTheme.getCategoryIcon(product.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDocuments(product),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 22,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.brand.isNotEmpty
                                ? '${product.brand} • ${product.category}'
                                : product.category,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
                      tooltip: 'Product Options',
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.primary),
                              SizedBox(width: 10),
                              Text('Documents & Bills'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimary),
                              SizedBox(width: 10),
                              Text('Edit Product'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Purchased: ${_formatDate(product.purchaseDate)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.event_available_outlined, size: 13, color: AppTheme.textSecondary),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Expires: ${_formatDate(product.warrantyExpiryDate)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: status, isCompact: true),
                  ],
                ),
                if (product.notes != null && product.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_rounded, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.notes!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Digital Warranty Vault'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ProductService.getReadableErrorMessage(snapshot.error),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final products = snapshot.data ?? [];

            if (products.isEmpty) {
              return EmptyStateView(
                icon: Icons.inventory_2_outlined,
                title: 'Your Warranty Vault is Empty',
                description:
                    'Store product invoices, calculate warranty expiry dates automatically, and get timely reminders.',
                actionLabel: 'Add Your First Product',
                actionIcon: Icons.add_rounded,
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProductFormScreen(),
                    ),
                  );
                },
              );
            }

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
                  _buildSearchAndFilterBar(products),
                  const SizedBox(height: 12),
                  if (_filter.isActive) ...[
                    _buildActiveFilterChips(),
                    const SizedBox(height: 14),
                  ],
                  if (_filter.isActive) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtered Results (${filteredProducts.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
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
                      _buildNoFilterResultsCard()
                    else
                      ...filteredProducts.map((p) => _buildProductCard(p)),
                  ] else ...[
                    _buildSummaryMetrics(
                      total: products.length,
                      active: activeProducts.length,
                      expiring: expiringProducts.length,
                      expired: expiredProducts.length,
                    ),
                    const SizedBox(height: 24),
                    if (expiringProducts.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'Expiring Soon',
                        count: expiringProducts.length,
                        icon: Icons.warning_amber_rounded,
                        accentColor: AppTheme.statusExpiringText,
                      ),
                      const SizedBox(height: 10),
                      ...expiringProducts.map((p) => _buildProductCard(p)),
                      const SizedBox(height: 20),
                    ],
                    _buildSectionHeader(
                      title: 'Active Warranties',
                      count: activeProducts.length,
                      icon: Icons.verified_user_rounded,
                      accentColor: AppTheme.statusActiveText,
                    ),
                    const SizedBox(height: 10),
                    if (activeProducts.isEmpty)
                      _buildEmptySectionCard('No active warranties currently registered.')
                    else
                      ...activeProducts.take(4).map((p) => _buildProductCard(p)),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      title: 'Recent Products',
                      count: recentProducts.length,
                      icon: Icons.history_rounded,
                      accentColor: AppTheme.primary,
                    ),
                    const SizedBox(height: 10),
                    if (recentProducts.isEmpty)
                      _buildEmptySectionCard('No recent products found.')
                    else
                      ...recentProducts
                          .take(5)
                          .map((p) => _buildProductCard(p)),
                  ],
                  const SizedBox(height: 84),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
        },
        tooltip: 'Add Product',
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}
