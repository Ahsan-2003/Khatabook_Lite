import 'package:hive/hive.dart';
import '../../domain/entities/customer.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 0)
class CustomerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? phoneNumber;

  @HiveField(3)
  final String? photoPath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Domain Entity
  Customer toEntity() {
    return Customer(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Convert from Domain Entity
  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      phoneNumber: customer.phoneNumber,
      photoPath: customer.photoPath,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }
}
