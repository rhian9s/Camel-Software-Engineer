import 'package:permission_handler/permission_handler.dart';

// This name must match your home_screen
class SimInfo {
  final String slot;
  final String carrier;
  final String number;
  final String balance;
  final int subId;
  SimInfo(this.slot, {required this.carrier, required this.number, required this.balance, required this.subId});
}

// Keep old name for compatibility
typedef SimInfoModel = SimInfo;

class SimService {
  // Your home_screen calls getLiveSims()
  Future<List<SimInfo>> getLiveSims() async {
    await Permission.phone.request();
    return [
      SimInfo("SIM 1", carrier: "MTN Rwanda", number: "078...", balance: "Check", subId: 0),
      SimInfo("SIM 2", carrier: "Airtel Rwanda", number: "073...", balance: "Check", subId: 1),
    ];
  }
  
  // Also keep getSimCards() for other screens
  Future<List<SimInfo>> getSimCards() => getLiveSims();
  Future<List<SimInfo>> getSims() => getLiveSims();
}
