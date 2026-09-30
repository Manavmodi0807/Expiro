import 'package:flutter/material.dart';
import '../../models/product_document_model.dart';
import '../../models/product_model.dart';
import '../../services/document_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_view.dart';
import 'document_viewer_screen.dart';
import 'ocr_scan_screen.dart';

class ProductDocumentsScreen extends StatefulWidget {
  final Product product;

  const ProductDocumentsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDocumentsScreen> createState() => _ProductDocumentsScreenState();
}

class _ProductDocumentsScreenState extends State<ProductDocumentsScreen> {
  final _documentService = DocumentService();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showStorageUnavailableNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.cloud_off_rounded, size: 44, color: AppTheme.statusExpiringText),
        title: const Text('Cloud Storage Unavailable'),
        content: const Text(
          'Document upload is currently unavailable because Firebase Cloud Storage is not enabled on the free Spark tier for this project.\n\nCloud Storage requires the Firebase billing-enabled (Blaze) plan.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understand'),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_rounded, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Document to Vault',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: AppTheme.primary, size: 22),
                  ),
                  title: const Text('Scan & Extract Text (OCR)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Extract readable text from bill or warranty card'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const OcrScanScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppTheme.secondary, size: 22),
                  ),
                  title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Take a photo of physical invoice or warranty slip'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showStorageUnavailableNotice();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF2563EB), size: 22),
                  ),
                  title: const Text('Select Image from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Choose JPG / PNG receipt image'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showStorageUnavailableNotice();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626), size: 22),
                  ),
                  title: const Text('Upload PDF Invoice', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select digital PDF invoice or receipt'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showStorageUnavailableNotice();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteDocument(ProductDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, size: 40, color: Color(0xFFDC2626)),
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${doc.fileName}" from this product? This action cannot be undone.',
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
        await _documentService.deleteDocument(
          productId: widget.product.id,
          document: doc,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Document removed from vault.'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = DocumentService.getReadableErrorMessage(e);
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final categoryIcon = AppTheme.getCategoryIcon(product.category);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Product Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, size: 22),
            tooltip: 'Scan Document (OCR)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OcrScanScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Product summary header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon,
                      size: 24,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),

            // Informational Spark limitation banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.statusExpiringBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.statusExpiringBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.statusExpiringText, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cloud Storage is disabled on the free Firebase Spark tier. Document management runs in readiness mode.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.statusExpiringText,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<ProductDocument>>(
                stream: _documentService.getDocumentsStream(product.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          DocumentService.getReadableErrorMessage(snapshot.error),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ),
                    );
                  }

                  final documents = snapshot.data ?? [];

                  if (documents.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.folder_zip_outlined,
                      title: 'No Documents Attached Yet',
                      description:
                          'Store invoices, receipts, and warranty cards for ${product.productName} in your digital vault.',
                      actionLabel: 'Add Document / Invoice',
                      actionIcon: Icons.add_photo_alternate_rounded,
                      onAction: _showAddDocumentOptions,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final isPdf = doc.isPdf;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPdf ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_outlined,
                              color: isPdf
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2563EB),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            doc.fileName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                '${doc.documentType} • ${_formatFileSize(doc.fileSizeBytes)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (doc.createdAt != null)
                                Text(
                                  'Added ${_formatDate(doc.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                            tooltip: 'Delete Document',
                            onPressed: () => _confirmDeleteDocument(doc),
                          ),
                          onTap: () {
                            if (doc.downloadUrl.isEmpty) {
                              _showStorageUnavailableNotice();
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DocumentViewerScreen(
                                  document: doc,
                                  productName: product.productName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDocumentOptions,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text(
          'Add Document',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}
