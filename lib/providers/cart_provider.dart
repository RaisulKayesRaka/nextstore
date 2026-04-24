import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/product_model.dart';
import '../core/models/coupon_model.dart';
import '../core/models/cart_item_model.dart';

export '../core/models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CartItem> _items = [];
  CouponModel? _appliedCoupon;
  String? _userId;
  bool _isFetching = false;

  List<CartItem> get items => _items;
  int get itemCount =>
      _items.fold(0, (previousValue, item) => previousValue + item.quantity);
  bool get isFetching => _isFetching;

  double get subTotal => _items.fold(
    0,
    (previousValue, item) =>
        previousValue + (item.product.price * item.quantity),
  );

  double get discountAmount {
    if (_appliedCoupon == null) return 0.0;
    if (_appliedCoupon!.discountType == 'percentage') {
      return subTotal * (_appliedCoupon!.discountValue / 100);
    } else {
      return _appliedCoupon!.discountValue;
    }
  }

  double get deliveryCharge => _items.isEmpty ? 0.0 : 100.0;
  double get finalTotal => subTotal - discountAmount + deliveryCharge;
  CouponModel? get appliedCoupon => _appliedCoupon;

  void updateUser(String? uid) {
    if (_userId != uid) {
      _userId = uid;
      if (_userId != null) {
        _fetchCartFromFirestore();
      } else {
        _items = [];
        _appliedCoupon = null;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    await _fetchCartFromFirestore();
  }

  Future<void> _fetchCartFromFirestore() async {
    if (_userId == null) return;

    _isFetching = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('carts').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> itemsList = data['items'] ?? [];
        _items = itemsList.map((item) => CartItem.fromMap(item)).toList();

        if (data['appliedCoupon'] != null) {
          _appliedCoupon = CouponModel.fromMap(
            data['appliedCoupon'],
            data['appliedCoupon']['id'] ?? '',
          );
          _validateCoupon();
        } else {
          _appliedCoupon = null;
        }
      }
    } catch (e) {
      debugPrint("Error fetching cart from Firestore: $e");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> _syncToFirestore() async {
    if (_userId == null) return;

    try {
      final cartRef = _firestore.collection('carts').doc(_userId);
      final itemsData = _items.map((item) => item.toMap()).toList();

      Map<String, dynamic> data = {
        'items': itemsData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_appliedCoupon != null) {
        final couponMap = _appliedCoupon!.toMap();
        couponMap['id'] = _appliedCoupon!.id;
        data['appliedCoupon'] = couponMap;
      } else {
        data['appliedCoupon'] = null;
      }

      await cartRef.set(data);
    } catch (e) {
      debugPrint("Error syncing cart to Firestore: $e");
    }
  }

  void addToCart(ProductModel product, [int quantity = 1]) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final existingQuantity = _items[index].quantity;
      _items[index] = CartItem(product: product, quantity: existingQuantity);

      final newQuantity = existingQuantity + quantity;
      if (newQuantity <= product.stockQuantity) {
        _items[index].quantity = newQuantity;
      } else {
        _items[index].quantity = product.stockQuantity;
      }
    } else {
      if (quantity <= product.stockQuantity) {
        _items.add(CartItem(product: product, quantity: quantity));
      } else {
        _items.add(CartItem(product: product, quantity: product.stockQuantity));
      }
    }
    _validateCoupon();
    notifyListeners();
    _syncToFirestore();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _validateCoupon();
    notifyListeners();
    _syncToFirestore();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= _items[index].product.stockQuantity) {
        _items[index].quantity = quantity;
      } else {
        _items[index].quantity = _items[index].product.stockQuantity;
      }
      _validateCoupon();
      notifyListeners();
      _syncToFirestore();
    }
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    notifyListeners();
    _syncToFirestore();
  }

  bool applyCoupon(CouponModel coupon) {
    if (coupon.isActive &&
        coupon.expiryDate.isAfter(DateTime.now()) &&
        subTotal >= coupon.minOrderAmount) {
      _appliedCoupon = coupon;
      notifyListeners();
      _syncToFirestore();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
    _syncToFirestore();
  }

  void _validateCoupon() {
    if (_appliedCoupon != null) {
      if (subTotal < _appliedCoupon!.minOrderAmount) {
        _appliedCoupon = null;
      }
    }
  }

  void syncWithProducts(List<ProductModel> latestProducts) {
    bool changed = false;
    for (int i = 0; i < _items.length; i++) {
      final latest = latestProducts
          .where((p) => p.id == _items[i].product.id)
          .firstOrNull;
      if (latest != null) {
        if (_items[i].product.stockQuantity != latest.stockQuantity ||
            _items[i].product.price != latest.price ||
            _items[i].product.name != latest.name ||
            _items[i].product.imageUrl != latest.imageUrl) {
          _items[i] = CartItem(product: latest, quantity: _items[i].quantity);

          if (_items[i].quantity > latest.stockQuantity) {
            _items[i].quantity = latest.stockQuantity;
          }
          changed = true;
        }
      }
    }
    if (changed) {
      notifyListeners();
    }
  }
}
