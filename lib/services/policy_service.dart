// lib/services/policy_service.dart
import '../models/company_policy.dart';
import 'network_service.dart';

class PolicyService {
  final NetworkService _network = NetworkService();

  // ── Fetch company policies ────────────────────────────────
  Future<List<CompanyPolicy>> getPolicies({
    String? category,
    String? search,
    bool? mandatory,
  }) async {
    final query = <String, String>{};
    if (category != null && category != 'all' && category.isNotEmpty) {
      query['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (mandatory != null) {
      query['mandatory'] = '$mandatory';
    }

    final response = await _network.get('/policies', query: query);

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List;
      return list
          .whereType<Map>()
          .map((e) => CompanyPolicy.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .where((p) => p.id.isNotEmpty)
          .toList();
    }
    return <CompanyPolicy>[];
  }

  // ── Get single policy detail ──────────────────────────────
  Future<CompanyPolicy?> getPolicyById(String id) async {
    if (id.isEmpty) return null;
    final response = await _network.get('/policies/$id');
    if (response is Map<String, dynamic> && response['data'] is Map) {
      final map = (response['data'] as Map).map((k, v) => MapEntry(k.toString(), v));
      return CompanyPolicy.fromJson(map);
    }
    return null;
  }

  // ── Employee acknowledge policy ───────────────────────────
  Future<Map<String, dynamic>> acknowledgePolicy(
    String id, {
    String comments = '',
  }) async {
    if (id.isEmpty) throw Exception('Policy ID is required');
    final response = await _network.post('/policies/$id/acknowledge', {
      'comments': comments.trim(),
    });

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true, 'message': 'Policy acknowledged'};
  }
}
