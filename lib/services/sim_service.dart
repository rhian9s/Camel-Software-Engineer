import 'package:permission_handler/permission_handler.dart';

class SimInfo {
  final String slot;
  final String carrier;
  final String number;
  final String balance;
  final int subId;
  SimInfo(this.slot, {required this.carrier, required this.number, required this.balance, required this.subId});
}

typedef SimInfoModel = SimInfo;

class SimService {
  static Future<List<SimInfo>> getLiveSims() async {
    await Permission.phone.request();
    return [
      SimInfo("SIM 1", carrier: "MTN Rwanda", number: "078...", balance: "Check", subId: 0),
      SimInfo("SIM 2", carrier: "Airtel Rwanda", number: "073...", balance: "Check", subId: 1),
    ];
  }
  
  static Future<List<SimInfo>> getSimCards() => getLiveSims();
  static Future<List<SimInfo>> getSims() => getLiveSims();
  
  // Instance versions too for compatibility
  Future<List<SimInfo>> getLiveSimsInstance() => getLiveSims();
}
