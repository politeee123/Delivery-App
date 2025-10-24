import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/create_delivery.dart';
import 'package:flutter_application_delivery/pages/delivery_detail.dart';
import 'package:flutter_application_delivery/pages/home_user.dart';
import 'package:flutter_application_delivery/pages/login.dart';
import 'package:flutter_application_delivery/pages/proflie.dart';
import 'package:flutter_application_delivery/pages/receiver_page.dart';
import 'package:flutter_application_delivery/pages/search_receiver_page.dart';
import 'package:flutter_application_delivery/pages/sender_delivery_map.dart';

class SenderPage extends StatefulWidget {
  final String id;
  const SenderPage({super.key, required this.id});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeUser(id: widget.id)),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceiverPage(id: widget.id)),
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
        title: const Text("Sender"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
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
            // 🔹 ปุ่มสร้าง Delivery
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SearchReceiverPage(senderId: widget.id),
                    ),
                  );
                },
                icon: const Icon(Icons.add_box),
                label: const Text("ส่งของ"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 รายการ Delivery
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('delivery')
                    .where('sender_id', isEqualTo: widget.id)
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("ยังไม่มีรายการส่งสินค้า"));
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
                            // 🔸 ดึงข้อมูลผู้รับ
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(data['receiver_id'])
                                .get(),
                            builder: (context, receiverSnap) {
                              final receiverData = receiverSnap.data?.data()
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
                                        "ชื่อผู้รับ: ${receiverData?['Name'] ?? '-'}",
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                      Text(
                                        "เบอร์: ${receiverData?['Phone'] ?? '-'}",
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
                                        builder: (context) => DeliveryDetailPage(
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

            // 🔹 ปุ่มดูการจัดส่งทั้งหมด (อยู่ก่อน Navbar)
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SenderDeliveryMapPage(senderId: widget.id),
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
