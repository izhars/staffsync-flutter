import '../models/feedback.dart';
import 'network_service.dart';

class FeedbackService {
  final NetworkService _network = NetworkService();

  /// SEND FEEDBACK (supports anonymous mode)
  Future<Map<String, dynamic>> sendFeedback(FeedbackModel feedback) async {
    final data = await _network.post("/feedbacks", feedback.toJson());

    return {
      'success': true,
      'data': data['feedback'],
    };
  }

  /// GET ALL FEEDBACKS (Admin/HR)
  Future<List<dynamic>> getAllFeedbacks() async {
    final data = await _network.get("/feedbacks");
    return data['feedbacks'] ?? [];
  }
}