import 'package:flutter/material.dart';
import '../services/sim_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// ===== CAMEL VAULT MODEL - MECHANICAL =====
class CamelBundle {
  String id; String type; double amount; double remaining;
  DateTime expiresAt; String from; String to;
  CamelBundle({required this.id, required this.type, required this.amount, required this.remaining, required this.expiresAt, required this.from, required this.to});
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  String get timeLeft { var d = expiresAt.difference(DateTime.now()); if(d.isNegative) return "Expired"; return "${d.inHours}h ${d.inMinutes%60}m"; }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<SimInfo> sims = [];
  List<CamelBundle> myVault = [];
  static const ussdChannel = MethodChannel('camel_wallet/ussd');
  late TabController _tab;
  final toController = TextEditingController();
  final amountController = TextEditingController();

  @override void initState() { 
    super.initState(); 
    _tab = TabController(length: 2, vsync: this);
    loadSims(); 
    // Demo vault data - in real app from Hive
    myVault = [
      CamelBundle(id: "CM-30M-24H-001", type: "minutes", amount: 30, remaining: 28, expiresAt: DateTime.now().add(const Duration(hours: 22)), from: "Self", to: "078..."),
      CamelBundle(id: "CM-5.4GB-7D-002", type: "data", amount: 5400, remaining: 5200, expiresAt: DateTime.now().add(const Duration(days: 6, hours: 4)), from: "Self", to: "Self"),
      CamelBundle(id: "CM-25M-24H-8F3K", type: "minutes", amount: 25, remaining: 25, expiresAt: DateTime.now().add(const Duration(hours: 23)), from: "078123456", to: "You - Received"),
    ];
    Timer.periodic(const Duration(seconds: 30), (_) => setState((){})); // countdown update
  }

  loadSims() async {
    if (await Permission.phone.request().isGranted) {
      var s = await SimService.getLiveSims();
      setState(() => sims = s);
    }
  }

  // ===== REAL USSD =====
  sendReal(SimInfo sim, String type, String to, String amount) async {
    String code;
    if(type=="Money") code="*182*1*1*$to*$amount#";
    else if(type=="Airtime") code="*182*3*2*$to*$amount#";
    else code="*182*2*7*$to*$amount#";
    showDialog(context: context, barrierDismissible: false, builder: (_)=> const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))));
    try{
      final resp = await ussdChannel.invokeMethod('sendUssd', {'code': code, 'subId': sim.subId});
      if(!mounted) return; Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp), backgroundColor: const Color(0xFF1B5E20)));
      // If success, add to Camel Vault mechanically
      if(type!="Money"){
        setState(() {
          myVault.add(CamelBundle(id: "CM-${DateTime.now().millisecondsSinceEpoch}", type: type=="Airtime"?"minutes":"data", amount: double.parse(amount), remaining: double.parse(amount), expiresAt: DateTime.now().add(Duration(hours: type=="Airtime"?24:168)), from: "Self-Bought", to: to));
        });
      }
    }catch(e){ if(mounted) Navigator.pop(context); }
  }

  // ===== MECHANICAL SEND FROM VAULT =====
  sendFromVault(CamelBundle bundle, String to) {
    // Deduct from vault, create gift for receiver
    setState(() { bundle.remaining -= bundle.amount; });
    // In real app: send via Firebase to receiver's phone number
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sent ${bundle.amount} ${bundle.type} to $to • Expires in ${bundle.timeLeft} • Receiver must use in 1 day!"), backgroundColor: const Color(0xFF1B5E20)));
  }

  void showRealSend(SimInfo sim, String type){
    toController.clear(); amountController.clear();
    showDialog(context: context, builder: (c)=> AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Send $type • Real USSD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: toController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "To 078xxx", labelStyle: const TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)))),
        const SizedBox(height: 10),
        TextField(controller: amountController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: type=="Data"?"MB (1024=1GB)":"Amount RWF", labelStyle: const TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)))),
      ]),
      actions: [ElevatedButton(onPressed: (){ Navigator.pop(context); sendReal(sim, type, toController.text, amountController.text); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)), child: Text("SEND $type REAL", style: const TextStyle(color: Colors.white)))],
    ));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Row(children: [Text("🐪 "), Text("Camel Wallet • Kinigi L0+", style: TextStyle(fontWeight: FontWeight.bold))]), backgroundColor: const Color(0xFF0A0A0A), foregroundColor: Colors.white, elevation: 0, bottom: TabBar(controller: _tab, indicatorColor: const Color(0xFF1B5E20), labelColor: Colors.white, unselectedLabelColor: Colors.white54, tabs: const [Tab(text: "Real USSD"), Tab(text: "Camel Vault ⏳")])),
      body: TabBarView(controller: _tab, children: [
        // TAB 1: REAL USSD - Money + Minutes + MBs via telco
        ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]), borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Real Balance • MTN + Airtel", style: TextStyle(color: Colors.white70)), Text("47,500 RWF", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), Text("Tap SIM → Check real USSD", style: TextStyle(color: Colors.white60, fontSize: 11))])),
          const SizedBox(height: 16),
          ...sims.map((sim)=> Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)), child: Column(children: [
            Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: sim.carrier.toLowerCase().contains("mtn")? const Color(0xFFFFCC00): Colors.red, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(sim.slot))), const SizedBox(width: 10), Text(sim.carrier, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: ()=> showRealSend(sim, "Money"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Money"))),
              const SizedBox(width: 6),
              Expanded(child: ElevatedButton(onPressed: ()=> showRealSend(sim, "Airtime"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Minutes", style: TextStyle(color: Colors.black)))),
              const SizedBox(width: 6),
              Expanded(child: ElevatedButton(onPressed: ()=> showRealSend(sim, "Data"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("MBs/GBs"))),
            ])
          ]))),
        ]),
        // TAB 2: CAMEL VAULT MECHANICAL - Time-limited bundles
        ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.account_balance_wallet, color: Color(0xFF1B5E20)), SizedBox(width: 8), Text("My Camel Vault • Mechanical", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 6),
            const Text("Bought bundles live here with expiry. Send to anyone, they must use in 24h!", style: TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
          const SizedBox(height: 12),
          ...myVault.map((b)=> Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: b.isExpired? Colors.red.withOpacity(0.1): const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: b.isExpired? Colors.red.withOpacity(0.3): Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [Icon(b.type=="minutes"?Icons.call:Icons.wifi, color: b.type=="minutes"? const Color(0xFFFFCC00): Colors.blue, size: 18), const SizedBox(width: 6), Text("${b.remaining} ${b.type=="minutes"?"min":"MB"} • ${b.from}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: b.isExpired? Colors.red: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(20)), child: Text(b.timeLeft, style: const TextStyle(color: Colors.white, fontSize: 10))),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: b.remaining/b.amount, backgroundColor: Colors.white10, color: b.isExpired? Colors.red: const Color(0xFF1B5E20)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: b.isExpired?null: ()=> sendFromVault(b, "078..."), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1B5E20))), child: Text(b.to.contains("Received")?"USE NOW • Call/Browse": "Send ${b.type=="minutes"?"25min/24h":"4GB"}", style: const TextStyle(color: Colors.white, fontSize: 11)))),
              if(b.to.contains("Received")) const SizedBox(width: 8),
              if(b.to.contains("Received")) Expanded(child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)), child: const Text("Sync to Phone", style: TextStyle(fontSize: 11, color: Colors.white)))),
            ])
          ]))),
          const SizedBox(height: 12),
          ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text("Buy 30min/24h (500 RWF) or 5.4GB/7days"), onPressed: ()=> showRealSend(sims.first, "Airtime"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
        ]),
      ]),
    );
  }
}
