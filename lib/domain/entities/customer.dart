class Customer {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? name,
    String? phoneNumber,
    String? photoPath,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
