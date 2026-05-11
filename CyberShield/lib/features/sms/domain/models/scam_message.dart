class ScamMessage {
  final String id;
  final String appName;
  final String sender;
  final String message;
  final int riskScore;
  final bool isScam;
  final DateTime timestamp;

  const ScamMessage({
    required this.id,
    required this.appName,
    required this.sender,
    required this.message,
    required this.riskScore,
    required this.isScam,
    required this.timestamp,
  });

  ScamMessage copyWith({
    String? id,
    String? appName,
    String? sender,
    String? message,
    int? riskScore,
    bool? isScam,
    DateTime? timestamp,
  }) {
    return ScamMessage(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      riskScore: riskScore ?? this.riskScore,
      isScam: isScam ?? this.isScam,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
