import 'package:sim_data/sim_data.dart';

class SimInfoModel {
  final String slot;
  final String carrier;
  final String number;
  final String balance;
  final int subId;

  SimInfoModel(this.slot, {required this.carrier, required this.number, required this.balance, required this.subId});
}

class SimService {
  Future<List<SimInfoModel>> getSimCards() async {
    try {
      final simData = await SimDataPlugin.getSimData();
      List<SimInfoModel> sims = [];

      for (var c in simData.cards) {
        // FIX: c.phoneNumber doesn't exist -> use displayName / carrierName
        String carrier = c.carrierName ?? "Unknown";
        String number = c.displayName ?? "";
        if (number.isEmpty) number = "07...";

        sims.add(SimInfoModel(
          "SIM ${(c.slotIndex ?? 0) + 1}",
          carrier: carrier,
          number: number,
          balance: "Loading...",
          subId: c.subscriptionId ?? 0,
        ));
      }
      return sims;
    } catch (e) {
      print("SIM Error: $e");
      return [];
    }
  }
}
class UssdService {
  static Future<String> sendUssd(String code, int slot) async {
    return "USSD: \$code SIM \${slot+1}";
  }
}
