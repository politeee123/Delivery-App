import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_delivery/firebase_option.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // เพิ่ม
import 'package:flutter_application_delivery/pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Connect Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // 🔹 Initialize Supabase (ใส่ URL + anon public key ของคุณตรงนี้)
  await Supabase.initialize(
    url: 'https://cfpoeeqozwxpfepkhmsc.supabase.co', // Project URL จาก Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmcG9lZXFvend4cGZlcGtobXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4ODA3NDMsImV4cCI6MjA3NDQ1Njc0M30.bYQmWiuUrUTsA9hQAM1ioxC6HtZIeVFQoBDGCIJyxYw', // anon public key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swift Drop',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginPage(),
    );
  }
}
