import 'package:flutter/material.dart';
import '../services/sim_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SimInfo> sims = [];
  static const ussdChannel = MethodChannel('camel_wallet/ussd');
  String moneyBalance = "--- RWF";
  String airtimeBalance = "--- RWF";
  String dataBalance = "--- MB";
  String totalBalance = "47,500";
  final toController = TextEditingController();
  final amountController = TextEditingController();

  @override void initState() { super.initState(); loadSims(); }
  loadSims() async {
    if (await Permission.phone.request().isGranted) {
      var s = await SimService.getLiveSims();
      setState(() => sims = s);
    }
  }

  checkBalance(SimInfo sim) async {
    String code = sim.carrier.toLowerCase().contains("mtn")? "*182*7*1#" : "*131#";
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))));
      final String response = await ussdChannel.invokeMethod('sendUssd', {'code': code, 'subId': sim.subId});
      if (!mounted) return; Navigator.pop(context);
      setState(() { moneyBalance = response.split("\n").first; totalBalance = RegExp(r'\d+').allMatches(response).first.group(0)?? totalBalance; });
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF121212), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (c){
        return Padding(padding: const EdgeInsets.fromLTRB(20,16,20,30), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text("${sim.carrier}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _premiumTile(Icons.account_balance_wallet, "MoMo Money", moneyBalance, const Color(0xFF1B5E20)),
          _premiumTile(Icons.phone_iphone, "Airtime", "1,200 RWF", Colors.orange),
          _premiumTile(Icons.wifi, "Internet", "1.2 GB", Colors.blue),
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)), child: Text(response, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ]));
      });
    } catch (e) {
      if (!mounted) return; Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tap again: $e"), backgroundColor: const Color(0xFF1B5E20)));
    }
  }

  sendMoney(SimInfo sim) async {
    showDialog(context: context, builder: (c)=> AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Send via ${sim.carrier}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: toController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "To: 078xxxxxxx", labelStyle: const TextStyle(color: Colors.white54), prefixIcon: const Icon(Icons.person, color: Colors.white54), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B5E20))))),
        const SizedBox(height: 12),
        TextField(controller: amountController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Amount RWF", labelStyle: const TextStyle(color: Colors.white54), prefixIcon: const Icon(Icons.money, color: Colors.white54), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B5E20))))),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
        ElevatedButton(onPressed: () async {
          Navigator.pop(context);
          String to = toController.text.trim(); String amount = amountController.text.trim();
          String ussdCode = "*182*1*1*$to*$amount#";
          try{
            showDialog(context: context, barrierDismissible: false, builder: (_)=> const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))));
            final resp = await ussdChannel.invokeMethod('sendUssd', {'code': ussdCode, 'subId': sim.subId});
            if (!mounted) return; Navigator.pop(context);
            showDialog(context: context, builder: (_)=> AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text("Confirm", style: TextStyle(color: Colors.white)), content: Text(resp, style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("OK"))]));
          }catch(e){ if (!mounted) return; Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"))); }
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  Widget _premiumTile(IconData icon, String title, String value, Color color){
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.08))), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
    ]));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text("Camel Wallet • Kinigi", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)), backgroundColor: const Color(0xFF0A0A0A), foregroundColor: Colors.white, elevation: 0, centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TOTAL BALANCE CARD - Camel-live style
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Balance", style: TextStyle(color: Colors.white70)), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: const Text("RWF", style: TextStyle(color: Colors.white, fontSize: 12)))]),
              const SizedBox(height: 8),
              Text("$totalBalance RWF", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [ _quickAction(Icons.call, "Airtime"), const SizedBox(width: 12), _quickAction(Icons.wifi, "Data"), const SizedBox(width: 12), _quickAction(Icons.lightbulb, "Bills"), const SizedBox(width: 12), _quickAction(Icons.school, "School") ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Text("My SIMs", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...sims.map((sim) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Column(children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: sim.carrier.toLowerCase().contains("mtn")? const Color(0xFFFFCC00) : const Color(0xFFE60000), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(sim.slot, style: TextStyle(color: sim.carrier.toLowerCase().contains("mtn")? Colors.black: Colors.white, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sim.carrier, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(sim.number, style: const TextStyle(color: Colors.white54, fontSize: 12))]),
                const Spacer(),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: ()=>checkBalance(sim), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.account_balance_wallet, size: 18), SizedBox(width: 6), Text("Balance")]))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: ()=>sendMoney(sim), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send, size: 18), SizedBox(width: 6), Text("Send")]))),
              ])
            ]),
          )),
        ],
      ),
    );
  }
  Widget _quickAction(IconData icon, String label){
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))]));
  }
}
