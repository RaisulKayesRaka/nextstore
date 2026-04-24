import 'address_model.dart';
import 'product_model.dart';

class OrderItem {
  final ProductModel product;
  final int quantity;

  OrderItem({required this.product, required this.quantity});

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      product: ProductModel.fromMap(
        data['product'],
        data['product']['id'] ?? '',
      ),
      quantity: data['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': {'id': product.id, ...product.toMap()},
      'quantity': quantity,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final AddressModel shippingAddress;
  final List<OrderItem> items;
  final double subTotal;
  final double discount;
  final double deliveryCharge;
  final double totalAmount;
  final String
  status; // 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.shippingAddress,
    required this.items,
    required this.subTotal,
    required this.discount,
    required this.deliveryCharge,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OrderModel(
      id: documentId,
      userId: data['userId'] ?? '',
      shippingAddress: AddressModel.fromMap(
        data['shippingAddress'],
        data['shippingAddress']['id'] ?? '',
      ),
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      subTotal: (data['subTotal'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      deliveryCharge: (data['deliveryCharge'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shippingAddress': {'id': shippingAddress.id, ...shippingAddress.toMap()},
      'items': items.map((e) => e.toMap()).toList(),
      'subTotal': subTotal,
      'discount': discount,
      'deliveryCharge': deliveryCharge,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
