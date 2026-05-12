import 'package:flutter/material.dart';

class AdminPusatScreen extends StatelessWidget {
  const AdminPusatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // const dihapus dari sini
      backgroundColor: Colors.red[50],
      body: const Center(child: Text('Ini Dashboard ADMIN PUSAT (Executive)', style: TextStyle(fontSize: 20))), // const dipindah ke sini
    );
  }
}