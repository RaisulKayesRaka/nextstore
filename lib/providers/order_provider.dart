import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _userOrders = [];
  List<OrderModel> _allOrders = []; // For admin
  bool _isLoading = false;

  List<OrderModel> get userOrders => _userOrders;
  List<OrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchUserOrders(String userId) async {
    setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      _userOrders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      _userOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint("Error fetching user orders: $e");
    }
    setLoading(false);
  }

  Future<void> fetchAllOrders() async {
    setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      _allOrders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching all orders: $e");
    }
    setLoading(false);
  }

  Future<bool> createOrder(OrderModel order) async {
    try {
      final success = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        List<DocumentSnapshot<Map<String, dynamic>>> productSnapshots = [];
        for (var item in order.items) {
          final productRef = _firestore
              .collection('products')
              .doc(item.product.id);
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            throw "Product ${item.product.name} no longer exists.";
          }

          final data = snapshot.data();
          final currentStock = data?['stockQuantity'] ?? 0;
          if (currentStock < item.quantity) {
            throw "Insufficient stock for ${item.product.name}. Only $currentStock left.";
          }
          productSnapshots.add(snapshot);
        }

        final orderRef = _firestore.collection('orders').doc();
        transaction.set(orderRef, order.toMap());

        for (int i = 0; i < order.items.length; i++) {
          final item = order.items[i];
          final snapshot = productSnapshots[i];
          final data = snapshot.data();
          final currentStock = data?['stockQuantity'] ?? 0;
          transaction.update(snapshot.reference, {
            'stockQuantity': currentStock - item.quantity,
          });
        }

        return true;
      });

      if (success) {
        fetchUserOrders(order.userId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Order creation failed: $e");
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      final index = _allOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _allOrders[index] = OrderModel(
          id: orderId,
          userId: _allOrders[index].userId,
          shippingAddress: _allOrders[index].shippingAddress,
          items: _allOrders[index].items,
          subTotal: _allOrders[index].subTotal,
          discount: _allOrders[index].discount,
          deliveryCharge: _allOrders[index].deliveryCharge,
          totalAmount: _allOrders[index].totalAmount,
          status: newStatus,
          createdAt: _allOrders[index].createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
