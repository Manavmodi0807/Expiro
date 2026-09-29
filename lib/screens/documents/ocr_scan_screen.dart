import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';

class OcrScanScreen extends StatefulWidget {
  final bool returnCandidateFields;

  const OcrScanScreen({
    super.key,
    this.returnCandidateFields = false,
  });

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  final _ocrService = OcrService();
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _isProcessing = false;
  OcrResult? _ocrResult;
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        // User cancelled selection
        return;
      }

      final imageFile = File(pickedFile.path);
      if (!await imageFile.exists()) {
        setState(() {
          _errorMessage = 'The selected image could not be loaded.';
        });
        return;
      }

      setState(() {
        _selectedImage = imageFile;
        _isProcessing = true;
        _ocrResult = null;
        _errorMessage = null;
      });

      final result = await _ocrService.processImageFile(imageFile.path);

      if (mounted) {
        setState(() {
          _ocrResult = result;
          _isProcessing = false;
          if (result.isEmpty) {
            _errorMessage = 'No text was detected in this image. Please try a clearer image.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = OcrService.getReadableErrorMessage(e);
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extracted text copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Extract Document Text'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Source selection card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Document Image',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture a photo or select an existing bill, invoice, or warranty card from your gallery.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _pickAndProcessImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Camera'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _pickAndProcessImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image preview if selected
              if (_selectedImage != null) ...[
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                    color: Colors.black12,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                      ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black45,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Extracting text on-device...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Detected candidate fields review (if any)
              if (_ocrResult != null && _ocrResult!.candidateFields.hasAnyField) ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Detected Information',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_ocrResult!.candidateFields.productName != null)
                          _buildCandidateRow(
                            'Product Name',
                            _ocrResult!.candidateFields.productName!,
                            Icons.inventory_2_outlined,
                          ),
                        if (_ocrResult!.candidateFields.brand != null)
                          _buildCandidateRow(
                            'Brand',
                            _ocrResult!.candidateFields.brand!,
                            Icons.branding_watermark_outlined,
                          ),
                        if (_ocrResult!.candidateFields.purchaseDate != null)
                          _buildCandidateRow(
                            'Purchase Date',
                            _formatDate(_ocrResult!.candidateFields.purchaseDate!),
                            Icons.calendar_today_outlined,
                          ),
                        if (_ocrResult!.candidateFields.warrantyDurationMonths != null)
                          _buildCandidateRow(
                            'Warranty Period',
                            '${_ocrResult!.candidateFields.warrantyDurationMonths} Months',
                            Icons.timer_outlined,
                          ),
                        if (widget.returnCandidateFields) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop(_ocrResult!.candidateFields);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Use in Product Form'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Extracted Raw Text Display
              if (_ocrResult != null && !_ocrResult!.isEmpty) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Extracted Text',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _copyToClipboard(_ocrResult!.rawText),
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              tooltip: 'Copy text',
                            ),
                          ],
                        ),
                        const Divider(),
                        SelectableText(
                          _ocrResult!.rawText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
