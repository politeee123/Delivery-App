import 'package:flutter/material.dart';

class ReceiverPage extends StatelessWidget {
  final String id;
  const ReceiverPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receiver")),
      body: Center(child: Text("Receiver Page\nUser ID: $id")),
    );
  }
}
