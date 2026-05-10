class ReportEntity {
  final String victimName;
  final String victimEmail;
  final String victimPhone;
  final String state;
  final String officialEmail;
  final String scamType;
  final String suspectContact;
  final String suspiciousLink;
  final String appName;
  final String transactionId;
  final String amount;
  final String description;
  final List<String> attachmentPaths;

  ReportEntity({
    required this.victimName,
    required this.victimEmail,
    required this.victimPhone,
    required this.state,
    required this.officialEmail,
    required this.scamType,
    required this.suspectContact,
    required this.suspiciousLink,
    required this.appName,
    required this.transactionId,
    required this.amount,
    required this.description,
    required this.attachmentPaths,
  });
}