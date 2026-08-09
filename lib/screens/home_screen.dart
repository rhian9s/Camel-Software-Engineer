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

  // Real balances
  String moneyBalance = "--- RWF";
  String airtimeBalance = "--- RWF";
  String dataBalance = "--- MB";
  String lastFullResponse = "";

  final toController = TextEditingController();
  final amountController = TextEditingController();

  @override void initState() { super.initState(); loadSims(); }

  loadSims() async {
    if (await Permission.phone.request().isGranted) {
      var s = await SimService.getLiveSims();
      setState(() => sims = s);
    }
  }

  // CHECK ALL BALANCES - Money + Airtime + MBs
  checkBalance(SimInfo sim) async {
    String code = sim.carrier.toLowerCase().contains("mtn")? "*182*7*1#" : "*131#";
    try {
      setState(() => lastFullResponse = "Checking...");
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      final String response = await ussdChannel.invokeMethod('sendUssd', {'code': code, 'subId': sim.subId});
      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        lastFullResponse = response;
        // Parse MTN response like "Amfranga: 12500 RWF, Airtime: 200 RWF, Internet: 450MB"
        moneyBalance = extractBalance(response, ["RWF", "Frw", "balance"])?? response;
        // For demo, split response
        if(response.contains("RWF")){
          var parts = response.split(RegExp(r'[\n,]'));
          moneyBalance = parts.isNotEmpty? parts[0] : response;
          airtimeBalance = parts.length > 1? parts[1] : "Check *182*7*1*2#";
          dataBalance = parts.length > 2? parts[2] : "Check *182*7*1*3#";
        }
      });

      // Show Beautiful Bottom Sheet
      showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (c){
        return Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 15),
          Text("${sim.carrier} - Your Wallet", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _balanceTile(Icons.account_balance_wallet, "MoMo Money", moneyBalance, Colors.green),
          _balanceTile(Icons.phone, "Airtime", airtimeBalance, Colors.orange),
          _balanceTile(Icons.wifi, "Internet", dataBalance, Colors.blue),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: Text(response, style: const TextStyle(fontSize: 12))),
          const SizedBox(height: 20),
        ]));
      });

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e - Tap again")));
    }
  }

  // SEND MONEY TO ANYONE - REAL
  sendMoney(SimInfo sim) async {
    showDialog(context: context, builder: (c)=> AlertDialog(
      title: Text("Send Money via ${sim.carrier}"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: toController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "To: 078xxxxxxx", prefixIcon: Icon(Icons.person))),
        TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount RWF", prefixIcon: Icon(Icons.money))),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          Navigator.pop(context);
          String to = toController.text.trim();
          String amount = amountController.text.trim();
          String ussdCode = "*182*1*1*$to*$amount#"; // MTN send
          if(sim.carrier.toLowerCase().contains("airtel")) ussdCode = "*182*1*1*$to*$amount#"; // Airtel similar

          try{
            showDialog(context: context, barrierDismissible: false, builder: (_)=> const Center(child: CircularProgressIndicator()));
            final resp = await ussdChannel.invokeMethod('sendUssd', {'code': ussdCode, 'subId': sim.subId});
            if (!mounted) return;
            Navigator.pop(context);
            showDialog(context: context, builder: (_)=> AlertDialog(title: const Text("Confirm"), content: Text(resp), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("OK"))]));
          }catch(e){
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Send failed: $e")));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)), child: const Text("SEND", style: TextStyle(color: Colors.white)))
      ],
    ));
  }

  String? extractBalance(String text, List<String> keywords){
    for(var k in keywords){ if(text.contains(k)) return text; } return null;
  }

  Widget _balanceTile(IconData icon, String title, String value, Color color){
    return Card(child: ListTile(leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)), title: Text(title), subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camel Wallet • Kinigi"), backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
      body: sims.isEmpty? const Center(child: Text("No SIMs found")) : ListView.builder(
        itemCount: sims.length,
        itemBuilder: (c,i){
          final sim = sims[i];
          return Card(margin: const EdgeInsets.all(12), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [CircleAvatar(backgroundColor: sim.carrier.toLowerCase().contains("mtn")? Colors.yellow: Colors.red, child: Text(sim.slot)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sim.carrier, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sim.number, style: const TextStyle(fontSize: 12))])]),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(child: ElevatedButton.icon(onPressed: ()=>checkBalance(sim), icon: const Icon(Icons.account_balance_wallet), label: const Text("Balance"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(onPressed: ()=>sendMoney(sim), icon: const Icon(Icons.send), label: const Text("Send"), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white))),
              ])
            ]),
          ));
        },
      ),
    );
  }
}
