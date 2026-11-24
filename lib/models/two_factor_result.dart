class TwoFactorRequired {
  final String ticket;
  final String maskedEmail;
  final String method;
  final int expiresInSeconds;

  TwoFactorRequired({
    required this.ticket,
    required this.maskedEmail,
    this.method = 'email',
    this.expiresInSeconds = 300,
  });

  factory TwoFactorRequired.fromJson(Map<String, dynamic> json) {
    return TwoFactorRequired(
      ticket: json['ticket']?.toString() ?? '',
      maskedEmail: json['maskedEmail']?.toString() ?? '',
      method: json['method']?.toString() ?? 'email',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 300,
    );
  }
}