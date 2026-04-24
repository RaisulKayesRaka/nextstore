class BannerModel {
  final String id;
  final String imageUrl;
  final String? redirectTo; // Can be a categoryId or productId
  final bool isActive;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.redirectTo,
    this.isActive = true,
  });

  factory BannerModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BannerModel(
      id: documentId,
      imageUrl: data['imageUrl'] ?? '',
      redirectTo: data['redirectTo'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'redirectTo': redirectTo,
      'isActive': isActive,
    };
  }
}
