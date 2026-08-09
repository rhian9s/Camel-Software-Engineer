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
  String status = "Tap Check to see real balance";

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
      setState(() => status = "Checking ${sim.carrier}...");
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final String balance = await ussdChannel.invokeMethod('sendUssd', {'code': code, 'subId': sim.subId});
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => status = balance);
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text("${sim.carrier} Balance"),
        content: Text(balance, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("OK"))],
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => status = "Error: $e");
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camel Wallet • PRO"), backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(16), color: Colors.green.shade50, width: double.infinity, child: Text(status, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: ListView.builder(
          itemCount: sims.length,
          itemBuilder: (c,i){
            final sim = sims[i];
            return Card(margin: const EdgeInsets.all(12), child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green, child: Text(sim.slot)),
              title: Text(sim.carrier, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(sim.number),
              trailing: ElevatedButton(onPressed: ()=>checkBalance(sim), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white), child: const Text("Check")),
            ));
          },
        ))
      ]),
    );
  }
}
