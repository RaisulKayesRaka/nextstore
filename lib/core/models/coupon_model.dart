class CouponModel {
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double minOrderAmount;
  final DateTime expiryDate;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0.0,
    required this.expiryDate,
    this.isActive = true,
  });

  factory CouponModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CouponModel(
      id: documentId,
      code: data['code'] ?? '',
      discountType: data['discountType'] ?? 'fixed',
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      minOrderAmount: (data['minOrderAmount'] ?? 0.0).toDouble(),
      expiryDate: data['expiryDate'] != null
          ? DateTime.parse(data['expiryDate'].toString())
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount,
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
