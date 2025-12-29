import 'api_exception.dart';
import 'network_service.dart';

class PayrollService {
  final NetworkService _networkService = NetworkService();

  Future<List<dynamic>> fetchMyPayrolls() async {
    try {
      final data = await _networkService.get('/payroll/my-payroll');

      if (data['payrolls'] == null || data['payrolls'].isEmpty) {
        throw ApiException(
          message: "No payroll data found",
          statusCode: 404,
        );
      }

      return data['payrolls'];

    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }
}