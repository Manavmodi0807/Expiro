import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_document_model.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _documentsCollection(String productId) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('products')
        .doc(productId)
        .collection('documents');
  }

  Stream<List<ProductDocument>> getDocumentsStream(String productId) {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(<ProductDocument>[]);
    }

    return _documentsCollection(productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductDocument.fromFirestore(doc)).toList();
    });
  }

  Future<ProductDocument> uploadDocument({
    required String productId,
    required File file,
    required String fileName,
    required String documentType,
    required String contentType,
  }) async {
    // Cloud Storage is not provisioned on the Spark free plan.
    // Gracefully reject upload attempts without creating fake metadata or fake storage records.
    throw FirebaseException(
      plugin: 'firebase_storage',
      code: 'storage-disabled',
      message:
          'Document upload is currently unavailable because Firebase Cloud Storage is not enabled for this project. Cloud Storage requires the Firebase billing-enabled plan.',
    );
  }

  Future<void> deleteDocument({
    required String productId,
    required ProductDocument document,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    final docRef = _documentsCollection(productId).doc(document.id);
    await docRef.delete();
  }

  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      if (error.code == 'storage-disabled') {
        return error.message ??
            'Document upload is currently unavailable because Firebase Cloud Storage is not enabled for this project.';
      }
      switch (error.code) {
        case 'permission-denied':
        case 'unauthorized':
          return 'Permission denied. You can only access your own documents.';
        case 'object-not-found':
          return 'Document file was not found.';
        case 'bucket-not-found':
          return 'Document upload is currently unavailable because Firebase Cloud Storage is not enabled for this project.';
        case 'canceled':
          return 'Upload was canceled.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
