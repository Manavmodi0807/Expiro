import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/notification_service.dart';
import '../../services/ocr_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../documents/ocr_scan_screen.dart';

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
  final Set<int> _selectedReminderIntervals = {30, 15, 7};

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

  Future<void> _scanDocumentWithOcr() async {
    final fields = await Navigator.of(context).push<OcrCandidateFields>(
      MaterialPageRoute(
        builder: (context) => const OcrScanScreen(returnCandidateFields: true),
      ),
    );

    if (fields != null && mounted) {
      int populatedCount = 0;
      setState(() {
        if (fields.productName != null && fields.productName!.isNotEmpty) {
          _nameController.text = fields.productName!;
          populatedCount++;
        }
        if (fields.brand != null && fields.brand!.isNotEmpty) {
          _brandController.text = fields.brand!;
          populatedCount++;
        }
        if (fields.purchaseDate != null) {
          _selectedPurchaseDate = fields.purchaseDate!;
          populatedCount++;
        }
        if (fields.warrantyDurationMonths != null && fields.warrantyDurationMonths! > 0) {
          _setDuration(fields.warrantyDurationMonths!);
          populatedCount++;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    populatedCount > 0
                        ? 'Populated $populatedCount field(s) from document. Please review and verify.'
                        : 'Document scanned. Please review details before saving.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_selectedReminderIntervals.isNotEmpty) {
        await NotificationService().requestNotificationPermissions();
      }

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

        await NotificationService().rescheduleProductReminders(
          updated,
          reminderIntervals: _selectedReminderIntervals.toList(),
        );
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
        final newProductId = await _productService.addProduct(newProduct);
        final savedProduct = newProduct.copyWith(id: newProductId);

        await NotificationService().scheduleProductReminders(
          savedProduct,
          reminderIntervals: _selectedReminderIntervals.toList(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Product updated successfully.' : 'Product added to vault.',
                ),
              ],
            ),
            backgroundColor: AppTheme.statusActiveText,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  @override
  Widget build(BuildContext context) {
    final expiryDate = _calculatedExpiryDate;
    final status = _calculatedStatus;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product to Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, size: 22),
            tooltip: 'Autofill with OCR',
            onPressed: _scanDocumentWithOcr,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Scan Document Action Banner
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _scanDocumentWithOcr,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan Bill or Warranty Document',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Extract product name, dates & duration with OCR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 1: PRODUCT INFORMATION
                _buildSectionTitle('Product Information', Icons.info_outline_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'e.g. MacBook Pro 14"',
                          prefixIcon: Icon(Icons.devices_rounded, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the product name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _brandController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Brand *',
                          hintText: 'e.g. Apple, Samsung, Sony',
                          prefixIcon: Icon(Icons.branding_watermark_outlined, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the brand name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: Product.defaultCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  AppTheme.getCategoryIcon(cat),
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(cat),
                              ],
                            ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 2: PURCHASE & WARRANTY DURATION
                _buildSectionTitle('Purchase & Warranty Duration', Icons.calendar_today_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Purchase Date Picker
                      InkWell(
                        onTap: _selectPurchaseDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date *',
                            prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
                            suffixIcon: Icon(Icons.arrow_drop_down_rounded, size: 24),
                          ),
                          child: Text(
                            _formatDate(_selectedPurchaseDate),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Warranty Duration Presets',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _buildPresetChip('6 Months', 6),
                          _buildPresetChip('1 Year (12 Mo)', 12),
                          _buildPresetChip('2 Years (24 Mo)', 24),
                          _buildPresetChip('3 Years (36 Mo)', 36),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Duration in Months *',
                          hintText: 'e.g. 12',
                          prefixIcon: Icon(Icons.timer_outlined, size: 20),
                          suffixText: 'Months',
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 3: AUTOMATIC WARRANTY CALCULATION SUMMARY
                _buildSectionTitle('Warranty Calculation Summary', Icons.calculate_outlined),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.event_outlined, size: 16, color: AppTheme.textSecondary),
                              SizedBox(width: 6),
                              Text(
                                'Purchase Date:',
                                style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            _formatDate(_selectedPurchaseDate),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: AppTheme.borderLight),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.event_available_rounded, size: 16, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text(
                                'Calculated Expiry:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatDate(expiryDate),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: AppTheme.borderLight),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: AppTheme.textSecondary),
                              SizedBox(width: 6),
                              Text(
                                'Vault Status:',
                                style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          StatusBadge(status: status),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 4: WARRANTY EXPIRY REMINDERS
                _buildSectionTitle('Warranty Expiry Reminders', Icons.notifications_active_outlined),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select when you want to receive local device notifications before warranty expiration:',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _buildReminderChip('30 Days Before', 30),
                          _buildReminderChip('15 Days Before', 15),
                          _buildReminderChip('7 Days Before', 7),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION 5: NOTES & DETAILS
                _buildSectionTitle('Additional Details (Optional)', Icons.notes_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Notes, Serial Number, or Retailer Details',
                      hintText: 'e.g. Serial #SN-92841, Retailer: BestBuy, Covered against hardware faults',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Save Button
                FilledButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Product Details' : 'Save Product to Vault',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, int months) {
    final isSelected = _durationMonths == months;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setDuration(months),
      selectedColor: AppTheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.borderLight,
      ),
    );
  }

  Widget _buildReminderChip(String label, int days) {
    final isSelected = _selectedReminderIntervals.contains(days);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedReminderIntervals.add(days);
          } else {
            _selectedReminderIntervals.remove(days);
          }
        });
      },
      selectedColor: AppTheme.secondaryContainer.withValues(alpha: 0.6),
      checkmarkColor: AppTheme.secondary,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.secondary : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.secondary : AppTheme.borderLight,
      ),
    );
  }
}
