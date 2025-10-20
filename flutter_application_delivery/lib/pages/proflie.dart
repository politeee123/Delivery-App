import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'location_profile.dart';

class ProfilePage extends StatelessWidget {
  final String id;

  const ProfilePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(id);

    return Scaffold(
      appBar: AppBar(
        title: const Text("โปรไฟล์ผู้ใช้"),
        backgroundColor: Colors.lightBlueAccent,
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

              if (!addressSnap.hasData || addressSnap.data!.docs.isEmpty) {
                return _buildProfile(
                  context,
                  data,
                  createdAtText,
                  addresses: [],
                );
              }

              List<Map<String, dynamic>> addresses = addressSnap.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

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
                const Icon(Icons.phone, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(data['Phone'] ?? 'ไม่พบเบอร์โทร'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(createdAtText),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ แสดงที่อยู่ทั้งหมด
            if (addresses.isNotEmpty)
              ...addresses.map((addr) {
                final name =
                    addr['name'] ??
                    addr['label'] ??
                    addr['Address'] ??
                    'ไม่มีชื่อที่อยู่';
                final detail =
                    addr['detail'] ??
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
                          content: Text(
                            "ไม่มีข้อมูลพิกัด GPS สำหรับที่อยู่นี้",
                          ),
                        ),
                      );
                    }
                  },

                  child: Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.home, color: Colors.green),
                      title: Text(name),
                      subtitle: Text("$detail\nLat: $lat  Lng: $lng"),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text("แก้ไขข้อมูล"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
