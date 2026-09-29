import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? productToEdit;

  const ProductFormScreen({super.key, this.productToEdit});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;

  late String _selectedCategory;
  late DateTime _selectedPurchaseDate;
  late int _durationMonths;

  bool _isSaving = false;

  bool get isEditing => widget.productToEdit != null;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.productName ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _durationMonths = p?.warrantyDurationMonths ?? 12;
    _durationController = TextEditingController(text: _durationMonths.toString());
    _notesController = TextEditingController(text: p?.notes ?? '');

    _selectedCategory = p?.category ?? Product.defaultCategories.first;
    if (!Product.defaultCategories.contains(_selectedCategory)) {
      _selectedCategory = Product.defaultCategories.first;
    }
    _selectedPurchaseDate = p?.purchaseDate ?? DateTime.now();

    _durationController.addListener(_onDurationTextChanged);
  }

  @override
  void dispose() {
    _durationController.removeListener(_onDurationTextChanged);
    _nameController.dispose();
    _brandController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onDurationTextChanged() {
    final parsed = int.tryParse(_durationController.text);
    if (parsed != null && parsed > 0 && parsed != _durationMonths) {
      setState(() {
        _durationMonths = parsed;
      });
    }
  }

  void _setDuration(int months) {
    setState(() {
      _durationMonths = months;
      _durationController.text = months.toString();
    });
  }

  DateTime get _calculatedExpiryDate {
    return Product.calculateExpiryDate(_selectedPurchaseDate, _durationMonths);
  }

  WarrantyStatus get _calculatedStatus {
    return Product.calculateWarrantyStatus(_calculatedExpiryDate);
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPurchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedPurchaseDate) {
      setState(() {
        _selectedPurchaseDate = picked;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final expiryDate = _calculatedExpiryDate;
      final notes = _notesController.text.trim();

      if (isEditing) {
        final updated = widget.productToEdit!.copyWith(
          productName: _nameController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim(),
          purchaseDate: _selectedPurchaseDate,
          warrantyDurationMonths: _durationMonths,
          warrantyExpiryDate: expiryDate,
          notes: notes.isEmpty ? null : notes,
        );
        await _productService.updateProduct(updated);
      } else {
        final newProduct = Product(
          id: '',
          productName: _nameController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim(),
          purchaseDate: _selectedPurchaseDate,
          warrantyDurationMonths: _durationMonths,
          warrantyExpiryDate: expiryDate,
          notes: notes.isEmpty ? null : notes,
        );
        await _productService.addProduct(newProduct);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Product updated successfully.' : 'Product added to vault.',
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expiryDate = _calculatedExpiryDate;
    final status = _calculatedStatus;
    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. MacBook Pro 14"',
                    prefixIcon: Icon(Icons.devices_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the product name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: Product.defaultCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Brand
                TextFormField(
                  controller: _brandController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Brand *',
                    hintText: 'e.g. Apple, Samsung, Sony',
                    prefixIcon: Icon(Icons.branding_watermark_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the brand name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Purchase Date Picker Field
                InkWell(
                  onTap: _selectPurchaseDate,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Purchase Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _formatDate(_selectedPurchaseDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Warranty Duration Input & Quick Presets
                Text(
                  'Warranty Duration',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text('6 Months'),
                      selected: _durationMonths == 6,
                      onSelected: (_) => _setDuration(6),
                    ),
                    ChoiceChip(
                      label: const Text('1 Year (12 Mo)'),
                      selected: _durationMonths == 12,
                      onSelected: (_) => _setDuration(12),
                    ),
                    ChoiceChip(
                      label: const Text('2 Years (24 Mo)'),
                      selected: _durationMonths == 24,
                      onSelected: (_) => _setDuration(24),
                    ),
                    ChoiceChip(
                      label: const Text('3 Years (36 Mo)'),
                      selected: _durationMonths == 36,
                      onSelected: (_) => _setDuration(36),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Duration in Months *',
                    hintText: 'e.g. 12',
                    prefixIcon: Icon(Icons.timer_outlined),
                    suffixText: 'Months',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter warranty duration in months.';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Please enter a valid positive number of months.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Automatic Calculation Preview Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Automatic Warranty Calculation',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expiry Date:'),
                          Text(
                            _formatDate(expiryDate),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status:'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes / Other Details
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Other Details (Optional)',
                    hintText: 'e.g. Serial number, retailer name, or warranty terms',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                FilledButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Product' : 'Add to Vault',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
