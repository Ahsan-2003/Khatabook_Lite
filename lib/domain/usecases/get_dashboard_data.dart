import 'package:khatabook_lite/data/repositories/transaction_repository.dart';

class DashboardData {
  final double totalOwedToVendor;
  final double totalVendorOwes;

  const DashboardData({
    required this.totalOwedToVendor,
    required this.totalVendorOwes,
  });
}

class GetDashboardData {
  final TransactionRepository repository;

  GetDashboardData(this.repository);

  Future<DashboardData> call() async {
    final totalOwed = await repository.getTotalOwedToVendor();
    final totalOwes = await repository.getTotalVendorOwes();

    return DashboardData(
      totalOwedToVendor: totalOwed,
      totalVendorOwes: totalOwes,
    );
  }
}
