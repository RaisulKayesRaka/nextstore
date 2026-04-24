class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String details;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.details,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AddressModel(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      details: data['details'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'details': details,
      'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    String? name,
    String? phone,
    String? details,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
