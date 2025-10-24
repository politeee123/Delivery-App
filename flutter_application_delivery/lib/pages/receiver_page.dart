import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/receiver_delivery_detail.dart'; // ✅ เปลี่ยนไฟล์ที่เชื่อม
import 'package:flutter_application_delivery/pages/home_user.dart';
import 'package:flutter_application_delivery/pages/login.dart';
import 'package:flutter_application_delivery/pages/proflie.dart';
import 'package:flutter_application_delivery/pages/receiver_delivery_map.dart';
import 'package:flutter_application_delivery/pages/sender_page.dart';

class ReceiverPage extends StatefulWidget {
  final String id;
  const ReceiverPage({super.key, required this.id});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeUser(id: widget.id)),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SenderPage(id: widget.id)),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage(id: widget.id)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Receiver"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text("Log out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 รายการของที่ถูกส่งมา
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('delivery')
                    .where('receiver_id', isEqualTo: widget.id)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("ยังไม่มีของที่ถูกส่งมาหาคุณ"));
                  }

                  final deliveries = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: deliveries.length,
                    itemBuilder: (context, index) {
                      final data =
                          deliveries[index].data() as Map<String, dynamic>;
                      final deliveryId = deliveries[index].id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Item')
                            .doc(data['product_id'])
                            .get(),
                        builder: (context, itemSnap) {
                          final itemData =
                              itemSnap.data?.data() as Map<String, dynamic>?;

                          return FutureBuilder<DocumentSnapshot>(
                            // 🔸 ดึงข้อมูลผู้ส่ง
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(data['sender_id'])
                                .get(),
                            builder: (context, senderSnap) {
                              final senderData = senderSnap.data?.data()
                                  as Map<String, dynamic>?;

                              return Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      itemData?['Image'] ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.image_not_supported,
                                              size: 40, color: Colors.grey),
                                    ),
                                  ),
                                  title: Text(
                                    itemData?['Item_name'] ?? 'ไม่พบชื่อสินค้า',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ชื่อผู้ส่ง: ${senderData?['Name'] ?? '-'}",
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                      Text(
                                        "เบอร์: ${senderData?['Phone'] ?? '-'}",
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                      Text(
                                        "สถานะ: ${data['status'] ?? '-'}",
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      color: Colors.green),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReceiverDeliveryDetailPage( // ✅ เปลี่ยนหน้าใหม่
                                                deliveryId: deliveryId),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // 🔹 ปุ่มดูแผนที่ทั้งหมด
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiverDeliveryMapPage(
                        receiverId: widget.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text("ดูการจัดส่งทั้งหมดบนแผนที่"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),

      // 🔹 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green[50],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: "Sender"),
          BottomNavigationBarItem(
              icon: Icon(Icons.move_to_inbox), label: "Receiver"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
