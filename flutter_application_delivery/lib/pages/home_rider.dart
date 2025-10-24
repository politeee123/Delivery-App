import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/login.dart';
import 'package:flutter_application_delivery/pages/profileRider.dart';
import 'package:flutter_application_delivery/pages/rider_delivery_detail.dart';

class HomeRider extends StatefulWidget {
  final String riderId;

  const HomeRider({super.key, required this.riderId});

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _HomeRiderState extends State<HomeRider> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfileRiderPage(riderId: widget.riderId)),
        );
        break;
    }
  }

  Future<String> _getProductName(String productId) async {
    try {
      final productSnapshot =
          await FirebaseFirestore.instance.collection('Item').doc(productId).get();

      if (productSnapshot.exists) {
        final data = productSnapshot.data() as Map<String, dynamic>;
        return data['Item_name'] ?? 'ไม่ทราบชื่อสินค้า';
      }
    } catch (e) {
      debugPrint('❌ Error getting product name: $e');
    }
    return 'ไม่ทราบชื่อสินค้า';
  }

  Future<Map<String, String>> _getUserNames(
      String senderId, String receiverId) async {
    String senderName = 'ไม่ทราบชื่อผู้ส่ง';
    String receiverName = 'ไม่ทราบชื่อผู้รับ';

    try {
      final senderSnap =
          await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      if (senderSnap.exists) {
        senderName = (senderSnap.data() as Map<String, dynamic>)['Name'] ?? senderName;
      }

      final receiverSnap =
          await FirebaseFirestore.instance.collection('users').doc(receiverId).get();
      if (receiverSnap.exists) {
        receiverName =
            (receiverSnap.data() as Map<String, dynamic>)['Name'] ?? receiverName;
      }
    } catch (e) {
      debugPrint('❌ Error getting user names: $e');
    }

    return {'sender': senderName, 'receiver': receiverName};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("หน้าหลักไรเดอร์"),
        backgroundColor: Colors.green,
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

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('delivery')
            .where('status', isEqualTo: '[1] รอไรเดอร์มารับสินค้า')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("ยังไม่มีงานรอรับในขณะนี้"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final deliveryId = docs[index].id;
              final productId = data['product_id'];
              final senderId = data['sender_id'];
              final receiverId = data['receiver_id'];

              return FutureBuilder(
                future: Future.wait([
                  _getProductName(productId),
                  _getUserNames(senderId, receiverId),
                ]),
                builder: (context, AsyncSnapshot<List<dynamic>> combinedSnap) {
                  if (!combinedSnap.hasData) {
                    return const ListTile(
                      title: Text('กำลังโหลดข้อมูล...'),
                      leading: CircularProgressIndicator(),
                    );
                  }

                  final productName = combinedSnap.data![0] as String;
                  final userNames = combinedSnap.data![1] as Map<String, String>;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.inventory, color: Colors.green),
                      title: Text(productName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ผู้ส่ง: ${userNames['sender']}"),
                          Text("ผู้รับ: ${userNames['receiver']}"),
                          const SizedBox(height: 5),
                          Text(data['status'] ?? '',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiderDeliveryDetail(
                              deliveryId: deliveryId,
                              riderId: widget.riderId,
                            ),
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
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "โปรไฟล์"),
        ],
      ),
    );
  }
}
