import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/home_user.dart';
import 'package:flutter_application_delivery/pages/login.dart';
import 'package:flutter_application_delivery/pages/receiver_page.dart';
import 'package:flutter_application_delivery/pages/sender_page.dart';
import 'package:intl/intl.dart';
import 'location_profile.dart';

class ProfilePage extends StatefulWidget {
  final String id;

  const ProfilePage({super.key, required this.id});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceiverPage(id: widget.id)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.id);

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("โปรไฟล์ผู้ใช้"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: const Text("Log out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userRef.get(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
          }

          var data = userSnap.data!.data() as Map<String, dynamic>;

          String createdAtText = 'ไม่มีข้อมูลวันที่';
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
            createdAtText = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
          }

          final addressRef = userRef.collection('addresses');

          return FutureBuilder<QuerySnapshot>(
            future: addressRef.get(),
            builder: (context, addressSnap) {
              if (addressSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Map<String, dynamic>> addresses = [];
              if (addressSnap.hasData && addressSnap.data!.docs.isNotEmpty) {
                addresses = addressSnap.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();
              }

              return _buildProfile(
                context,
                data,
                createdAtText,
                addresses: addresses,
              );
            },
          );
        },
      ),

      // ✅ Bottom Navigation Bar
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
          BottomNavigationBarItem(icon: Icon(Icons.move_to_inbox), label: "Receiver"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // 🔹 UI ส่วนโปรไฟล์
  Widget _buildProfile(
    BuildContext context,
    Map<String, dynamic> data,
    String createdAtText, {
    required List<Map<String, dynamic>> addresses,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: (data['Image'] != null && data['Image'] != '')
                  ? NetworkImage(data['Image'])
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
            ),
            const SizedBox(height: 20),
            Text(
              data['Name'] ?? 'ไม่มีชื่อ',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 8),
                Text(data['Phone'] ?? 'ไม่พบเบอร์โทร'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, color: Colors.green),
                const SizedBox(width: 8),
                Text(createdAtText),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),

            // ✅ แสดงที่อยู่ทั้งหมด
            if (addresses.isNotEmpty)
              ...addresses.map((addr) {
                final name = addr['name'] ??
                    addr['label'] ??
                    addr['Address'] ??
                    'ไม่มีชื่อที่อยู่';
                final detail = addr['detail'] ??
                    addr['addressDetail'] ??
                    addr['Detail'] ??
                    '';
                final lat = addr['lat'];
                final lng = addr['lng'];

                return GestureDetector(
                  onTap: () {
                    if (lat != null && lng != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationProfilePage(
                            latitude: lat,
                            longitude: lng,
                            addressName: name,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("ไม่มีข้อมูลพิกัด GPS สำหรับที่อยู่นี้"),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.green[100],
                    child: ListTile(
                      leading: const Icon(Icons.home, color: Colors.green),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "$detail\nLat: $lat  Lng: $lng",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                );
              })
            else
              const Text(
                "ยังไม่มีข้อมูลที่อยู่",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }
}
