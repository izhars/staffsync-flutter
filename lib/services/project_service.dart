import 'network_service.dart';
import 'auth_service.dart';

class ProjectService {
  final NetworkService _networkService;
  final AuthService _authService = AuthService();

  ProjectService({NetworkService? networkService})
      : _networkService = networkService ?? NetworkService();

  // -------------------- CREATE PROJECT --------------------
  Future<Map<String, dynamic>> addProject(Map<String, dynamic> projectData) async {
    // 1. Role check
    final userData = await _authService.getUserData();
    final role = (userData?['role'] ?? '').toString().toLowerCase();
    print('🔑 [ADD_PROJECT] user role: "$role"');

    final allowedRoles = ['manager', 'superadmin', 'hr_admin', 'admin', 'hr'];
    if (!allowedRoles.contains(role)) {
      return {
        'success': false,
        'message': 'Only managers and HR/Admins can create projects (your role: "$role")',
      };
    }

    // 2. Build body with defaults
    final body = {
      'name': (projectData['name'] ?? '').toString().trim(),
      'code': (projectData['code'] ?? '').toString().trim(),
      'description': (projectData['description'] ?? '').toString().trim(),
      'startDate': projectData['startDate'] ?? '',
      'endDate': projectData['endDate'] ?? '',
      'budget': projectData['budget'] ?? 0.0,
      'tags': projectData['tags'] ?? <String>[],
      if (projectData['status'] != null) 'status': projectData['status'],
      if (projectData['priority'] != null) 'priority': projectData['priority'],
      if (projectData['progress'] != null) 'progress': projectData['progress'],
      if (projectData['manager'] != null) 'manager': projectData['manager'],
    };

    print('📤 [ADD_PROJECT] payload: $body');

    try {
      final response = await _networkService.post('/projects', body);

      print('✅ [ADD_PROJECT] response: $response');

      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Project created successfully',
      };
    } catch (e, stack) {
      print('❌ [ADD_PROJECT] error: $e');
      print('❌ [ADD_PROJECT] stack: $stack');
      return {
        'success': false,
        'message': _formatError(e),
      };
    }
  }

  // -------------------- GET ALL PROJECTS --------------------
  Future<Map<String, dynamic>> getAllProjects({
    int page = 1,
    int limit = 50,
    String? search,
    String? status,
    String? managerId,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (managerId != null && managerId.isNotEmpty) 'manager': managerId,
    };

    try {
      final endpoint = '/projects';
      final response = queryParams.isEmpty
          ? await _networkService.get(endpoint)
          : await _networkService
          .get('$endpoint?${Uri(queryParameters: queryParams).query}');

      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Projects fetched successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- GET SINGLE PROJECT --------------------
  Future<Map<String, dynamic>> getProject(String projectId) async {
    try {
      final response = await _networkService.get('/projects/$projectId');
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Project fetched successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- UPDATE PROJECT --------------------
  Future<Map<String, dynamic>> updateProject(
      String projectId,
      Map<String, dynamic> updates,
      ) async {
    try {
      final response =
      await _networkService.put('/projects/$projectId', updates);

      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Project updated successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- UPDATE PROGRESS --------------------
  Future<Map<String, dynamic>> updateProgress(
      String projectId,
      int progress, {
        String? status,
      }) async {
    try {
      final body = {
        'progress': progress,
        if (status != null) 'status': status,
      };
      final response = await _networkService.patch('/projects/$projectId/progress', body);
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Progress updated',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- DELETE PROJECT --------------------
  Future<Map<String, dynamic>> deleteProject(String projectId) async {
    try {
      final response = await _networkService.delete('/projects/$projectId');
      return {
        'success': true,
        'data': response,
        'message': response['message'] ?? 'Project deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- PROJECT CHAT --------------------
  Future<Map<String, dynamic>> getProjectMessages(String projectId) async {
    try {
      final response = await _networkService.get('/projects/$projectId/messages');
      return {
        'success': true,
        'data': response['data'] ?? [],
        'message': response['message'] ?? 'Messages fetched',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> sendProjectMessage(
      String projectId, {
        required String text,
        List<Map<String, dynamic>>? attachments,
      }) async {
    try {
      final body = {
        'text': text,
        if (attachments != null) 'attachments': attachments,
      };
      final response = await _networkService.post('/projects/$projectId/messages', body);
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Message sent',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> uploadChatAttachment(
      String projectId,
      String filePath,
      ) async {
    try {
      final response = await _networkService.uploadFileWithMethod(
        '/projects/$projectId/messages/upload',
        filePath,
        {},
        'file',
        'POST',
      );
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'File uploaded',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- PROJECT TASKS --------------------
  Future<Map<String, dynamic>> getProjectTasks(String projectId) async {
    try {
      final response = await _networkService.get('/projects/$projectId/tasks');
      return {
        'success': true,
        'data': response['data'] ?? [],
        'message': response['message'] ?? 'Tasks fetched',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> createProjectTask(
      String projectId,
      Map<String, dynamic> taskData,
      ) async {
    try {
      final response = await _networkService.post('/projects/$projectId/tasks', taskData);
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Task created',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> updateProjectTask(
      String projectId,
      String taskId,
      Map<String, dynamic> updates,
      ) async {
    try {
      final response = await _networkService.put('/projects/$projectId/tasks/$taskId', updates);
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Task updated',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> deleteProjectTask(
      String projectId,
      String taskId,
      ) async {
    try {
      final response = await _networkService.delete('/projects/$projectId/tasks/$taskId');
      return {
        'success': true,
        'data': response,
        'message': response['message'] ?? 'Task deleted',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- PROJECT ROLES CRUD --------------------
  Future<Map<String, dynamic>> getProjectRoles() async {
    try {
      final response = await _networkService.get('/project-roles');
      return {
        'success': true,
        'data': response['data'] ?? [],
        'message': response['message'] ?? 'Roles fetched successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> createProjectRole(
      Map<String, dynamic> roleData) async {
    try {
      final response = await _networkService.post('/project-roles', roleData);
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Role created successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> updateProjectRole(
      String roleId,
      Map<String, dynamic> updates,
      ) async {
    try {
      final response =
      await _networkService.patch('/project-roles/$roleId', updates);
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Role updated successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> deleteProjectRole(String roleId) async {
    try {
      final response = await _networkService.delete('/project-roles/$roleId');
      return {
        'success': true,
        'message': response['message'] ?? 'Role deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- TEAM MEMBERS --------------------
  Future<Map<String, dynamic>> addTeamMember({
    required String projectId,
    required String employeeId,
    required String roleId,
    required int allocation,
    List<Map<String, dynamic>>? responsibilities,
  }) async {
    final body = {
      'employee': employeeId,
      'role': roleId,
      'allocation': allocation,
      if (responsibilities != null && responsibilities.isNotEmpty)
        'responsibilities': responsibilities,
    };

    try {
      final response = await _networkService.post(
        '/projects/$projectId/team-members',
        body,
      );
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Team member added successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> removeTeamMember(
      String projectId,
      String teamMemberId,
      ) async {
    try {
      final response = await _networkService
          .delete('/projects/$projectId/team-members/$teamMemberId');
      return {
        'success': true,
        'message': response['message'] ?? 'Team member removed successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  Future<Map<String, dynamic>> getProjectTeam(String projectId) async {
    try {
      final response =
      await _networkService.get('/projects/$projectId/team-members');
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Team members fetched successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- GET PROJECTS FOR DROPDOWN --------------------
  Future<Map<String, dynamic>> getProjectsForDropdown() async {
    try {
      final response = await _networkService.get('/projects?limit=100&page=1');
      final projectsData = response['data']['projects'] ?? [];

      final dropdownOptions = projectsData.map<Map<String, dynamic>>((project) {
        return {
          'value': project['_id'] ?? project['id'],
          'label': '${project['name']} (${project['code']})',
          'project': project,
        };
      }).toList();

      return {
        'success': true,
        'data': dropdownOptions,
        'message': response['message'] ?? 'Projects fetched successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- ADD EXPENSE --------------------
  Future<Map<String, dynamic>> addExpense({
    required String projectId,
    required double amount,
    String? remark,
    DateTime? date,
  }) async {
    final body = {
      'amount': amount,
      if (remark != null && remark.isNotEmpty) 'remark': remark,
      if (date != null) 'date': date.toIso8601String(),
    };

    try {
      final response = await _networkService.post(
        '/projects/$projectId/expenses',
        body,
      );
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Expense recorded successfully',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- GET EXPENSE HISTORY --------------------
  Future<Map<String, dynamic>> getExpenseHistory(String projectId) async {
    try {
      final response =
      await _networkService.get('/projects/$projectId/expenses');
      return {
        'success': true,
        'data': response['data'],
        'message': response['message'] ?? 'Expense history fetched',
      };
    } catch (e) {
      return {'success': false, 'message': _formatError(e)};
    }
  }

  // -------------------- CHECK IF USER IS MEMBER --------------------
  Future<bool> isUserInProject(String projectId) async {
    try {
      final response =
      await _networkService.get('/projects/$projectId/is-member');
      return response['isMember'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // -------------------- HELPER --------------------
  String _formatError(dynamic error) {
    final s = error.toString();

    if (s.contains('SocketException') ||
        s.contains('TimeoutException') ||
        s.contains('Failed host lookup') ||
        s.contains('Connection refused')) {
      return 'Network error. Please check your connection.';
    }

    return s.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }
}
