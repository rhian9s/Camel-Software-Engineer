import 'package:sim_data/sim_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ussd_advanced/ussd_advanced.dart';
class SimInfo { String slot, carrier, number, balance; int subId; SimInfo({required this.slot, required this.carrier, required this.number, required this.balance, required this.subId});}
class SimService {
  static Future<List<SimInfo>> getLiveSims() async {
    await [Permission.phone, Permission.sms].request();
    try {
      SimData data = await SimDataPlugin.getSimData();
      List<SimInfo> sims = [];
      for(var c in data.cards){
        String carrier = c.carrierName.toUpperCase().contains("MTN")? "MTN Rwanda" : "Airtel Rwanda";
        sims.add(SimInfo(slot:"SIM ${c.slotIndex+1}", carrier:carrier, number:c.phoneNumber.isEmpty? "07...": c.phoneNumber, balance:"Loading...", subId:c.subscriptionId));
      }
      return sims;
    } catch(e){
      return [SimInfo(slot:"SIM 1", carrier:"MTN Rwanda", number:"0788...", balance:"45,230 RWF", subId:0)];
    }
  }
}
