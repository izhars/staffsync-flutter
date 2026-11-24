class FeedbackModel {
  final String message;
  final String category;
  final bool isAnonymous;

  FeedbackModel({
    required this.message,
    required this.category,
    required this.isAnonymous,
  });

  Map<String, dynamic> toJson() => {
    'message': message,
    'category': category,
    'isAnonymous': isAnonymous,
  };

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
    message: json['message'] ?? '',
    category: json['category'] ?? 'other',
    isAnonymous: json['isAnonymous'] ?? false,
  );
}