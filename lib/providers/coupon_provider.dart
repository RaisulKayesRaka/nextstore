import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/coupon_model.dart';

class CouponProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CouponModel> _coupons = [];
  bool _isLoading = false;

  List<CouponModel> get coupons => _coupons;
  bool get isLoading => _isLoading;

  CouponProvider() {
    fetchCoupons();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchCoupons() async {
    setLoading(true);
    try {
      final snapshot = await _firestore.collection('coupons').get();
      _coupons = snapshot.docs
          .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching coupons: $e");
    }
    setLoading(false);
  }

  Future<CouponModel?> getCouponByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase().trim())
          .get();
      if (snapshot.docs.isNotEmpty) {
        return CouponModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
    } catch (e) {
      debugPrint("Coupon fetch error: $e");
    }
    return null;
  }

  Future<bool> addCoupon(CouponModel coupon) async {
    try {
      final docRef = await _firestore.collection('coupons').add(coupon.toMap());
      final newCoupon = CouponModel(
        id: docRef.id,
        code: coupon.code,
        discountType: coupon.discountType,
        discountValue: coupon.discountValue,
        minOrderAmount: coupon.minOrderAmount,
        expiryDate: coupon.expiryDate,
        isActive: coupon.isActive,
      );
      _coupons.add(newCoupon);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCoupon(CouponModel coupon) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(coupon.id)
          .update(coupon.toMap());
      final index = _coupons.indexWhere((c) => c.id == coupon.id);
      if (index != -1) {
        _coupons[index] = coupon;
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCoupon(String id) async {
    try {
      await _firestore.collection('coupons').doc(id).delete();
      _coupons.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
