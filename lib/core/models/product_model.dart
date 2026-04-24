class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String imageUrl; // Main/Thumbnail image
  final List<String> images; // Additional images
  final bool isFeatured;
  final int stockQuantity;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    this.images = const [],
    this.isFeatured = false,
    this.stockQuantity = 0,
    required this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
      stockQuantity: data['stockQuantity'] ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'images': images,
      'isFeatured': isFeatured,
      'stockQuantity': stockQuantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    List<String>? images,
    bool? isFeatured,
    int? stockQuantity,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt,
    );
  }
}
