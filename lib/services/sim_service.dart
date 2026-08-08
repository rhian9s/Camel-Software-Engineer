import 'package:permission_handler/permission_handler.dart';
class SimInfoModel {
  final String slot; final String carrier; final String number; final String balance; final int subId;
  SimInfoModel(this.slot,{required this.carrier,required this.number,required this.balance,required this.subId});
}
class SimService {
  Future<List<SimInfoModel>> getSimCards() async {
    await Permission.phone.request();
    return [
      SimInfoModel("SIM 1",carrier:"MTN Rwanda",number:"078...",balance:"Check",subId:0),
      SimInfoModel("SIM 2",carrier:"Airtel Rwanda",number:"073...",balance:"Check",subId:1),
    ];
  }
}
