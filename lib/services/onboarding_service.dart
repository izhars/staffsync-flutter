import '../models/onboarding_model.dart';
import 'api_exception.dart';
import 'network_service.dart';

class OnboardingService {
  final NetworkService _network = NetworkService();

  static const _base = '/onboarding';

  // ── GET /onboarding/me ─────────────────────────────────
  // Employee ke apne onboarding ko fetch karta hai.
  // 404 milta hai jab tak HR initiate nahi karta.
  Future<OnboardingModel?> getMyOnboarding() async {
    try {
      final res = await _network.get('$_base/me');
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return OnboardingModel.fromJson(data);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null; // no onboarding yet
      rethrow;
    }
  }

  // ── GET /onboarding/:id ────────────────────────────────
  Future<OnboardingModel> getById(String id) async {
    final res = await _network.get('$_base/$id');
    return OnboardingModel.fromJson(res['data']);
  }

  // ── PATCH /onboarding/:id/checklist/:key ───────────────
  // Employee apni task-type checklist items tick/untick kar sakta hai.
  // Document-type items backend pe block hain (upload required).
  Future<OnboardingModel> toggleChecklistItem({
    required String onboardingId,
    required String key,
    required bool completed,
  }) async {
    final res = await _network.patch(
      '$_base/$onboardingId/checklist/${Uri.encodeComponent(key)}',
      {'completed': completed},
    );
    return OnboardingModel.fromJson(res['data']);
  }

  // ── POST /onboarding/:id/documents ─────────────────────
  // Employee apna document upload karta hai.
  // Backend `type` field require karta hai (aadhar/pan/…).
  Future<OnboardingModel> uploadDocument({
    required String onboardingId,
    required String filePath,
    required String type,
    String? notes,
  }) async {
    final fields = <String, String>{'type': type};
    if (notes != null && notes.trim().isNotEmpty) {
      fields['notes'] = notes.trim();
    }

    final res = await _network.uploadFile(
      '$_base/$onboardingId/documents',
      filePath,
      fields,
      'file', // backend multer field name
    );
    return OnboardingModel.fromJson(res['data']);
  }

  // ── DELETE /onboarding/:id/documents/:docId ────────────
  // Employee apna galat uploaded doc delete kar sakta hai
  // (agar backend allow kare — canAccessOnboarding pass hota hai).
  Future<OnboardingModel> deleteDocument({
    required String onboardingId,
    required String docId,
  }) async {
    final res = await _network.delete('$_base/$onboardingId/documents/$docId');
    return OnboardingModel.fromJson(res['data']);
  }
}