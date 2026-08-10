class CamelBundle {
  String id; // CM-xxx
  String type; // "minutes" or "data"
  double amount; // 25 min or 4000 MB
  double remaining;
  DateTime boughtAt;
  DateTime expiresAt; // 24h or 7days
  String from; // sender phone
  String to; // receiver
  bool isUsed;
}

bool isExpired() => DateTime.now().isAfter(expiresAt);
String get timeLeft {
  var diff = expiresAt.difference(DateTime.now());
  if(diff.isNegative) return "Expired";
  return "${diff.inHours}h ${diff.inMinutes%60}m left";
}
