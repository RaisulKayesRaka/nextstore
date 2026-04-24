import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get enabledCategories =>
      _categories.where((c) => c.isEnabled).toList();
  bool get isLoading => _isLoading;

  CategoryProvider() {
    fetchCategories();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    setLoading(true);
    try {
      final snapshot = await _firestore.collection('categories').get();
      _categories = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
    setLoading(false);
  }

  Future<String?> addCategory(CategoryModel category) async {
    try {
      final docRef = await _firestore
          .collection('categories')
          .add(category.toMap());
      final newCat = CategoryModel(
        id: docRef.id,
        name: category.name,
        imageUrl: category.imageUrl,
        isEnabled: category.isEnabled,
      );
      _categories.add(newCat);
      notifyListeners();
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
