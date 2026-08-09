import 'package:sim_data/sim_data.dart';

class SimInfo {
  final String slot;
  final String carrier;
  final String number;
  final int subId;
  SimInfo(this.slot, {required this.carrier, required this.number, required this.subId});
}

class SimService {
  static Future<List<SimInfo>> getLiveSims() async {
    try {
      var data = await SimDataPlugin.getSimData();
      List<SimInfo> list = [];
      for (var card in data.cards) {
        list.add(SimInfo(
          "SIM ${card.slotIndex + 1}",
          carrier: card.carrierName.isEmpty? "MTN Rwanda" : card.carrierName,
          number: card.displayName,
          subId: card.subscriptionId,
        ));
      }
      return list;
    } catch (e) {
      return [];
    }
  }
}
