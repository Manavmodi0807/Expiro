import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDocument {
  final String id;
  final String fileName;
  final String documentType;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int fileSizeBytes;
  final DateTime? createdAt;

  static const List<String> defaultDocumentTypes = [
    'Bill / Invoice',
    'Warranty Card',
    'Purchase Receipt',
    'User Manual / Other',
  ];

  ProductDocument({
    required this.id,
    required this.fileName,
    required this.documentType,
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.fileSizeBytes,
    this.createdAt,
  });

  bool get isPdf =>
      contentType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  bool get isImage =>
      contentType.startsWith('image/') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.webp');

  factory ProductDocument.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProductDocument(
      id: doc.id,
      fileName: data['fileName'] as String? ?? 'Untitled Document',
      documentType: data['documentType'] as String? ?? 'Bill / Invoice',
      storagePath: data['storagePath'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      contentType: data['contentType'] as String? ?? 'application/octet-stream',
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fileName': fileName,
      'documentType': documentType,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'fileSizeBytes': fileSizeBytes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
