import 'package:flutter/material.dart';
import '../services/sim_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SimInfo> sims = [];
  @override
  void initState() { super.initState(); loadSims(); }
  loadSims() async {
    var s = await SimService.getLiveSims();
    setState(() => sims = s);
  }

  checkBalance(SimInfo sim) async {
    await Permission.phone.request();
    String code = sim.carrier.contains("MTN")? "*182*7*1#" : "*131#";
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${sim.carrier} Balance"),
        content: Text("Dial:\n\n$code"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri(scheme: 'tel', path: code);
              await launchUrl(uri);
            },
            child: const Text("Dial Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camel Wallet • LIVE"), backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
      body: ListView.builder(
        itemCount: sims.length,
        itemBuilder: (c,i){
          final sim = sims[i];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(sim.carrier),
              subtitle: Text(sim.number),
              trailing: TextButton(onPressed: () => checkBalance(sim), child: const Text("Check")),
            ),
          );
        },
      ),
    );
  }
}
