class ScanModel {
  final String url;
  final String status;
  final int riskScore;

  ScanModel({
    required this.url,
    required this.status,
    required this.riskScore,
  });

  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      url: json["url"] ?? "",
      status: json["status"] ?? "",
      riskScore: json["riskScore"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "url": url,
      "status": status,
      "riskScore": riskScore,
    };
  }
}