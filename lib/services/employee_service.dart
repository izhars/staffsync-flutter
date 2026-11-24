import '../screens/call/call_tracking_service.dart';
import 'network_service.dart';

class EmployeeService {
  final NetworkService _network = NetworkService();

  /// 🔹 Get all employees
  Future<List<Map<String, dynamic>>> getAllEmployees({bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final response = await _network.get("/employees");

      if (response['success'] == true && response['employees'] != null) {
        final List<dynamic> list = response['employees'];

        return list.map<Map<String, dynamic>>((emp) {
          return {
            'id': emp['_id'] ?? emp['id'],
            'employeeId': emp['employeeId'] ?? '',
            'firstName': emp['firstName'] ?? '',
            'lastName': emp['lastName'] ?? '',
            'fullName': '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim(),
            'email': emp['email'] ?? '',
            'phone': emp['phone'] ?? '',
            'designation': emp['designation'] ?? '',
            'department': emp['department'] is Map
                ? Map<String, dynamic>.from(emp['department'])
                : {},
            'profilePicture': emp['profilePicture'] ?? '',
            'role': emp['role'] ?? 'employee',
            'isActive': emp['isActive'] ?? true,
            'status': emp['status'] ?? 'active',
            'createdAt': emp['createdAt'],
            'updatedAt': emp['updatedAt'],
            'lastLogin': emp['lastLogin'],
            'lastSeen': emp['lastSeen'],
            // Add other fields you might need for chat
            'fcmToken': emp['fcmToken'] ?? '',
            'socketIds': emp['socketIds'] ?? [],
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error fetching employees: $e');
      throw Exception('Failed to load employees');
    }
  }

  /// 🔹 Get employee list with optional isActive filter
  Future<List<Map<String, dynamic>>> getEmployeeListWithStatus({bool? isActive}) async {
    try {
      // Build query params if needed
      final queryParams = <String, dynamic>{};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      // Fetch data from API
      final response = await _network.get("/employees/last-seen");

      if (response['success'] == true && response['employees'] != null) {
        final List<dynamic> list = response['employees'];

        return list.map<Map<String, dynamic>>((emp) {
          final name = emp['name'] ?? '';
          final department = emp['department'] is Map
              ? Map<String, dynamic>.from(emp['department'])
              : {};

          return {
            'id': emp['id'],
            'employeeId': emp['employeeId'] ?? '',
            'fullName': name,
            'firstName': emp['firstName'] ?? '',
            'lastName': emp['lastName'] ?? '',
            'email': emp['email'] ?? '',
            'phone': emp['phone'] ?? '',
            'designation': emp['designation'] ?? '',
            'department': department,
            'role': emp['role'] ?? 'employee',
            'isActive': emp['isActive'] ?? true,
            'status': emp['status'] ??
                (emp['currentConnections'] > 0 ? 'active' : 'inactive'),
            'createdAt': emp['createdAt'],
            'updatedAt': emp['updatedAt'],
            'lastLogin': emp['lastLogin'],
            'lastSeen': emp['lastSeen'] ?? (emp['isOnline'] == true ? 'Now' : 'Never'),
            'fcmToken': emp['fcmToken'] ?? '',
            'socketIds': emp['socketConnections'] ?? [],
            // 👇 THIS IS THE MISSING PIECE
            'profilePicture': emp['profilePicture'] ?? '',
            'isOnline': emp['isOnline'] ?? false,
            'currentConnections': emp['currentConnections'] ?? 0,
            'reportingManager': emp['reportingManager'], // pass through if needed
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error fetching employees: $e');
      throw Exception('Failed to load employees');
    }
  }

  /// 🔹 Get employees by role
  Future<List<Map<String, dynamic>>> getEmployeesByRole(String role) async {
    try {
      final allEmployees = await getEmployeeListWithStatus(isActive: true);
      return allEmployees
          .where((emp) => emp['role']?.toString().toLowerCase() == role.toLowerCase())
          .toList();
    } catch (e) {
      print('❌ Error fetching employees by role: $e');
      return [];
    }
  }

  /// 🔹 Search employees
  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      final allEmployees = await getEmployeeListWithStatus(isActive: true);

      if (query.isEmpty) return allEmployees;

      final lowercaseQuery = query.toLowerCase();

      return allEmployees.where((emp) {
        final departmentName = emp['department']?['name']?.toString().toLowerCase() ?? '';
        return emp['fullName']?.toLowerCase().contains(lowercaseQuery) == true ||
            emp['employeeId']?.toLowerCase().contains(lowercaseQuery) == true ||
            emp['email']?.toLowerCase().contains(lowercaseQuery) == true ||
            emp['designation']?.toLowerCase().contains(lowercaseQuery) == true ||
            departmentName.contains(lowercaseQuery) ||
            emp['phone']?.contains(query) == true;
      }).toList();
    } catch (e) {
      print('❌ Error searching employees: $e');
      return [];
    }
  }

  /// 🔹 Get employee by ID
  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    try {
      final allEmployees = await getAllEmployees();
      return allEmployees.firstWhere(
            (emp) => emp['id'] == id,
        orElse: () => {},
      );
    } catch (e) {
      print('❌ Error getting employee by ID: $e');
      return null;
    }
  }

  /// 🔹 Get employees by department
  Future<List<Map<String, dynamic>>> getEmployeesByDepartment(String departmentId) async {
    try {
      final allEmployees = await getAllEmployees(isActive: true);
      return allEmployees
          .where((emp) => emp['department']['_id'] == departmentId)
          .toList();
    } catch (e) {
      print('❌ Error fetching employees by department: $e');
      return [];
    }
  }

  /// 🔹 Get all HRs (already asked earlier, keeping it clean)
  Future<List<Map<String, dynamic>>> getAllHRs() async {
    try {
      final response = await _network.get("/employees/hr");

      if (response['success'] == true && response['hrs'] != null) {
        final List<dynamic> hrList = response['hrs'];

        return hrList.map<Map<String, dynamic>>((hr) {
          return {
            '_id': hr['_id'] ?? hr['id'],
            'firstName': hr['firstName'] ?? '',
            'lastName': hr['lastName'] ?? '',
            'fullName':
            '${hr['firstName'] ?? ''} ${hr['lastName'] ?? ''}'.trim(),
            'email': hr['email'] ?? '',
            'employeeId': hr['employeeId'] ?? '',
            'designation': hr['designation'] ?? '',
            'department': hr['department'] is Map
                ? Map<String, dynamic>.from(hr['department'])
                : {},
            'profilePicture': hr['profilePicture'] ?? '',
            'isActive': hr['isActive'] ?? false,
            'isAvailable': hr['isAvailable'] ?? false,
            'availabilityStatus': hr['availabilityStatus'] ?? '',
            'nextAvailableAt': hr['nextAvailableAt'],
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error fetching HRs: $e');
      throw Exception('Failed to load HRs');
    }
  }

  /// Track profile view
  Future<Map<String, dynamic>> trackProfileView(String employeeId) async {
    try {
      final response = await _network.post(
        '/employee-interactions/view-profile/$employeeId',
        {},
      );
      return response;
    } catch (e) {
      print('❌ Error tracking profile view: $e');
      rethrow;
    }
  }

  /// Track contact view
  Future<Map<String, dynamic>> trackContactView(String employeeId) async {
    try {
      final response = await _network.post(
        '/employee-interactions/view-contact/$employeeId',
        {},
      );
      return response;
    } catch (e) {
      print('❌ Error tracking contact view: $e');
      rethrow;
    }
  }

  /// Send message notification
  Future<Map<String, dynamic>> sendMessageNotification(
      String receiverId,
      String message
      ) async {
    try {
      final response = await _network.post(
        '/employee-interactions/message',
        {
          'receiverId': receiverId,
          'message': message,
        },
      );
      return response;
    } catch (e) {
      print('❌ Error sending message notification: $e');
      rethrow;
    }
  }

  /// Track profile share
  Future<Map<String, dynamic>> trackProfileShare(
      String employeeId,
      String platform
      ) async {
    try {
      final response = await _network.post(
        '/employee-interactions/share-profile',
        {
          'employeeId': employeeId,
          'sharePlatform': platform,
        },
      );
      return response;
    } catch (e) {
      print('❌ Error tracking profile share: $e');
      rethrow;
    }
  }

  /// Track contact save
  Future<Map<String, dynamic>> trackContactSave(String employeeId) async {
    try {
      final response = await _network.post(
        '/employee-interactions/save-contact',
        {
          'employeeId': employeeId,
        },
      );
      return response;
    } catch (e) {
      print('❌ Error tracking contact save: $e');
      rethrow;
    }
  }

  /// Get interaction history
  Future<List<Map<String, dynamic>>> getInteractionHistory({
    int limit = 50,
    int offset = 0,
    String? interactionType,
  }) async {
    try {
      final params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (interactionType != null) 'interactionType': interactionType,
      };

      final response = await _network.getWithParams(
        '/employee-interactions/history',
        params: params,
      );

      return List<Map<String, dynamic>>.from(response['interactions'] ?? []);
    } catch (e) {
      print('❌ Error getting interaction history: $e');
      rethrow;
    }
  }

  /// Get interaction statistics
  Future<Map<String, dynamic>> getInteractionStatistics() async {
    try {
      final response = await _network.get(
        '/employee-interactions/statistics',
      );
      return response;
    } catch (e) {
      print('❌ Error getting interaction statistics: $e');
      rethrow;
    }
  }
}
