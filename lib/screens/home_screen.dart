import 'package:flutter/material.dart';
import '../services/sim_service.dart';
class HomeScreen extends StatefulWidget { @override _HomeScreenState createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  List<SimInfo> sims = []; bool loading = true;
  @override void initState(){ super.initState(); load(); }
  load() async { var s = await SimService.getLiveSims(); setState((){ sims=s; loading=false; }); }
  @override Widget build(BuildContext context){
    if(loading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(appBar: AppBar(title: Text("Camel Wallet • LIVE"), backgroundColor: Color(0xFF1B4332), foregroundColor: Colors.white),
      body: ListView(padding: EdgeInsets.all(16), children: [
       ...sims.map((s)=> Card(child: ListTile(title: Text(s.carrier), subtitle: Text(s.number), trailing: Text(s.balance, style: TextStyle(fontWeight: FontWeight.bold))))).toList(),
      ]));
  }
}
