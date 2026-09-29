import 'package:flutter/material.dart';
import '../../models/product_document_model.dart';
import '../../models/product_model.dart';
import '../../services/document_service.dart';
import 'document_viewer_screen.dart';

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
        icon: const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orange),
        title: const Text('Cloud Storage Unavailable'),
        content: const Text(
          'Document upload is currently unavailable because Firebase Cloud Storage is not enabled for this project.\n\nCloud Storage requires the Firebase billing-enabled (Blaze) plan.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.camera_alt_outlined),
                  ),
                  title: const Text('Capture Document with Camera'),
                  subtitle: const Text('Take a photo of bill or warranty card'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showStorageUnavailableNotice();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.photo_library_outlined),
                  ),
                  title: const Text('Select Image from Gallery'),
                  subtitle: const Text('Choose JPG / PNG receipt image'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showStorageUnavailableNotice();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.picture_as_pdf_outlined),
                  ),
                  title: const Text('Upload PDF Document'),
                  subtitle: const Text('Select PDF invoice or warranty document'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showStorageUnavailableNotice();
                  },
                ),
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
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${doc.fileName}"? This action cannot be undone.',
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
        await _documentService.deleteDocument(
          productId: widget.product.id,
          document: doc,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully.'),
              behavior: SnackBarBehavior.floating,
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
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text('${product.productName} Documents'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Product summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          '${product.brand} • ${product.category}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Informational Banner regarding Cloud Storage status
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cloud Storage is not enabled on this Firebase plan. Document uploads are currently in view/readiness mode.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
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
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    );
                  }

                  final documents = snapshot.data ?? [];

                  if (documents.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.file_present_rounded,
                              size: 72,
                              color: colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Documents Attached',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bills, invoices, and warranty documents for this product will appear here once Cloud Storage is enabled.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _showAddDocumentOptions,
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: const Text('Add Document'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final isPdf = doc.isPdf;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isPdf
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_outlined,
                              color: isPdf
                                  ? Colors.red.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                          title: Text(
                            doc.fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${doc.documentType} • ${_formatFileSize(doc.fileSizeBytes)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (doc.createdAt != null)
                                Text(
                                  'Uploaded: ${_formatDate(doc.createdAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Document'),
      ),
    );
  }
}
