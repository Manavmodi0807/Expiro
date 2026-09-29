import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _userProductsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('products');
  }

  Stream<List<Product>> getProductsStream() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(<Product>[]);
    }

    return _userProductsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  Future<String> addProduct(Product product) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    final collection = _userProductsCollection(userId);
    final docRef = await collection.add(product.toFirestore(isNew: true));
    return docRef.id;
  }

  Future<void> updateProduct(Product product) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    if (product.id.isEmpty) {
      throw Exception('Cannot update product without a valid ID.');
    }

    final docRef = _userProductsCollection(userId).doc(product.id);
    await docRef.update(product.toFirestore(isNew: false));
  }

  Future<void> deleteProduct(String productId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    if (productId.isEmpty) {
      throw Exception('Cannot delete product without a valid ID.');
    }

    final docRef = _userProductsCollection(userId).doc(productId);
    await docRef.delete();
  }

  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission denied. You can only access your own products.';
        case 'unavailable':
          return 'Service is currently unavailable. Please check your network connection.';
        case 'not-found':
          return 'The requested product was not found.';
        default:
          return error.message ?? 'A database error occurred. Please try again.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
