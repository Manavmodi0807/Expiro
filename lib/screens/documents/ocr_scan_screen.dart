import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_theme.dart';

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
            _errorMessage = 'No text was detected in this document. Please try a clearer image with good lighting.';
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Extracted text copied to clipboard.'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Scan & Extract Document Text'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Source selection card
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.document_scanner_rounded, color: AppTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Select Document to Scan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Capture a bill photo or pick an invoice from your gallery. On-device ML Kit will extract warranty details.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.35,
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
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _pickAndProcessImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Image preview if selected
              if (_selectedImage != null) ...[
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
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
                          color: Colors.black.withValues(alpha: 0.55),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                SizedBox(height: 14),
                                Text(
                                  'Extracting information on-device...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
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
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppTheme.statusExpiringBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.statusExpiringBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.statusExpiringText, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.statusExpiringText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Detected candidate fields review card
              if (_ocrResult != null && _ocrResult!.candidateFields.hasAnyField) ...[
                Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Detected Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_ocrResult!.candidateFields.productName != null)
                        _buildCandidateRow(
                          'Product Name',
                          _ocrResult!.candidateFields.productName!,
                          Icons.devices_rounded,
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
                          Icons.calendar_month_outlined,
                        ),
                      if (_ocrResult!.candidateFields.warrantyDurationMonths != null)
                        _buildCandidateRow(
                          'Warranty Duration',
                          '${_ocrResult!.candidateFields.warrantyDurationMonths} Months',
                          Icons.timer_outlined,
                        ),
                      if (widget.returnCandidateFields) ...[
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(_ocrResult!.candidateFields);
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('Use in Product Form'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Extracted Raw Text Display
              if (_ocrResult != null && !_ocrResult!.isEmpty) ...[
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.text_snippet_outlined, size: 18, color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Text(
                                'Full Extracted Text',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(_ocrResult!.rawText),
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primary),
                            tooltip: 'Copy all text',
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.borderLight),
                      const SizedBox(height: 8),
                      SelectableText(
                        _ocrResult!.rawText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontFamily: 'monospace',
                          color: AppTheme.textPrimary,
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
    );
  }

  Widget _buildCandidateRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
