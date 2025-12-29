import 'network_service.dart';

class EmployeeService {
  final NetworkService _network = NetworkService();

  /// Get all HRs with proper parsing
  Future<List<Map<String, dynamic>>> getAllHRs() async {
    try {
      final response = await _network.get("/employees/hr");

      if (response['success'] == true && response['hrs'] != null) {
        final List<dynamic> hrList = response['hrs'];

        // Transform the data to match expected format
        return hrList.map<Map<String, dynamic>>((hr) {
          return {
            '_id': hr['id'],  // Map 'id' to '_id' for consistency
            'firstName': hr['firstName'] ?? '',
            'lastName': hr['lastName'] ?? '',
            'fullName': '${hr['firstName'] ?? ''} ${hr['lastName'] ?? ''}'.trim(),
            'email': hr['email'] ?? '',
            'employeeId': hr['employeeId'] ?? '',
            'profilePicture': hr['profilePicture'] ?? '',
            'designation': hr['designation'] ?? '',
            'department': hr['department'] is Map
                ? Map<String, dynamic>.from(hr['department'])
                : {},
            'isActive': hr['isActive'] ?? false,
            'isAvailable': hr['isAvailable'] ?? false,
            'availabilityStatus': hr['availabilityStatus'] ?? '',
            'nextAvailableAt': hr['nextAvailableAt'],
            'availabilityLastChanged': hr['availabilityLastChanged'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching HRs: $e');
      throw Exception('Failed to load HRs');
    }
  }
}