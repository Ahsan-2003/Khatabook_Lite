import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phoneNumber;

  @HiveField(3)
  String? photoPath;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });
}
