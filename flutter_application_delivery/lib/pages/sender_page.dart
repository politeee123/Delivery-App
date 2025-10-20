import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/create_delivery.dart';

class SenderPage extends StatelessWidget {
  final String id;
  const SenderPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sender"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center( // ✅ เพิ่ม Center เพื่อจัดกลางแนวนอนและแนวตั้ง
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ ปรับให้ขนาดพอดีกับปุ่ม ไม่ยืดเต็มจอ
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateDeliveryPage(senderId: id),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping),
                label: const Text("Create Delivery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => MyDeliveriesPage(senderId: id),
                  // ));
                },
                icon: const Icon(Icons.list),
                label: const Text("My Deliveries"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
