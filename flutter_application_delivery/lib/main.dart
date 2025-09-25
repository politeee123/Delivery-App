import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // เอา debug ออก
      title: 'Swift Drop',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginPage(), // หน้าแรก
    );
  }
}
