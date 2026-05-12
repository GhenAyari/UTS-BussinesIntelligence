import 'package:flutter/material.dart';

class AdminDaerahScreen extends StatelessWidget {
  const AdminDaerahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // const dihapus dari sini
      backgroundColor: Colors.orange[50],
      body: const Center(child: Text('Ini Dashboard ADMIN DAERAH (BPBD)', style: TextStyle(fontSize: 20))), // const dipindah ke sini
    );
  }
}