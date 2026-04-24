import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _currentSort = 'Newest';

  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts =>
      _products.where((p) => p.isFeatured).toList();
  bool get isLoading => _isLoading;
  String get currentSort => _currentSort;

  ProductProvider() {
    _initProductsListener();
  }

  void _initProductsListener() {
    _isLoading = true;
    _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _products = snapshot.docs
                .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
                .toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error listening to products: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> fetchProducts() async {
    _initProductsListener();
  }

  List<ProductModel> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(lowerQuery) ||
              p.description.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  void sortProducts(String sortType) {
    _currentSort = sortType;
    if (sortType == 'Price: Low to High') {
      _products.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortType == 'Price: High to Low') {
      _products.sort((a, b) => b.price.compareTo(a.price));
    } else if (sortType == 'Newest') {
      _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      final docRef = await _firestore
          .collection('products')
          .add(product.toMap());
      final newProd = ProductModel(
        id: docRef.id,
        name: product.name,
        description: product.description,
        price: product.price,
        categoryId: product.categoryId,
        imageUrl: product.imageUrl,
        images: product.images,
        isFeatured: product.isFeatured,
        stockQuantity: product.stockQuantity,
        createdAt: product.createdAt,
      );
      _products.insert(0, newProd);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
