class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isEnabled;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isEnabled = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CategoryModel(
      id: documentId,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isEnabled: data['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'imageUrl': imageUrl, 'isEnabled': isEnabled};
  }
}
