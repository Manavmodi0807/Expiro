import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/product_document_model.dart';
import '../../theme/app_theme.dart';

class DocumentViewerScreen extends StatefulWidget {
  final ProductDocument document;
  final String productName;

  const DocumentViewerScreen({
    super.key,
    required this.document,
    required this.productName,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  String? _localPdfPath;
  bool _isLoadingPdf = false;
  String? _pdfError;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.document.isPdf) {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoadingPdf = true;
      _pdfError = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.document.id}.pdf');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localPdfPath = file.path;
            _isLoadingPdf = false;
          });
        }
        return;
      }

      final ref = FirebaseStorage.instance.ref(widget.document.storagePath);
      await ref.writeToFile(file);

      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          _isLoadingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfError = 'Could not load PDF document. Please check your connection.';
          _isLoadingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.fileName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.productName} • ${doc.documentType}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final doc = widget.document;

    if (doc.isImage) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            doc.downloadUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load image document',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'The image file could not be fetched from storage.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (doc.isPdf) {
      if (_isLoadingPdf) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading PDF document...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }

      if (_pdfError != null || _localPdfPath == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _pdfError ?? 'Failed to display PDF',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadPdf,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          PDFView(
            filePath: _localPdfPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page ?? 0;
                _totalPages = total ?? 0;
              });
            },
            onError: (error) {
              setState(() {
                _pdfError = error.toString();
              });
            },
          ),
          if (_totalPages > 0)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.layers_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              doc.fileName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Content Type: ${doc.contentType}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
