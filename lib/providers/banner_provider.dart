import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/banner_model.dart';

class BannerProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BannerModel> _banners = [];
  bool _isLoading = false;

  List<BannerModel> get banners => _banners;
  List<BannerModel> get activeBanners =>
      _banners.where((b) => b.isActive).toList();
  bool get isLoading => _isLoading;

  BannerProvider() {
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('banners').get();
      _banners = snapshot.docs
          .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBanner(BannerModel banner) async {
    try {
      final doc = await _firestore.collection('banners').add(banner.toMap());
      _banners.add(
        BannerModel(
          id: doc.id,
          imageUrl: banner.imageUrl,
          redirectTo: banner.redirectTo,
          isActive: banner.isActive,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding banner: $e");
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _firestore.collection('banners').doc(id).delete();
      _banners.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting banner: $e");
    }
  }
}
