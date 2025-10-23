import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/home_rider.dart'; // ✅ import หน้าแรกของไรเดอร์

class ProfileRiderPage extends StatefulWidget {
  final String riderId;

  const ProfileRiderPage({super.key, required this.riderId});

  @override
  State<ProfileRiderPage> createState() => _ProfileRiderPageState();
}

class _ProfileRiderPageState extends State<ProfileRiderPage> {
  int _selectedIndex = 1; // ✅ index เริ่มต้นที่หน้าโปรไฟล์

  void _onItemTapped(int index) {
    if (index == 0) {
      // 👉 ไปหน้า HomeRider
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeRider(riderId: widget.riderId),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderRef =
        FirebaseFirestore.instance.collection('riders').doc(widget.riderId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("โปรไฟล์ไรเดอร์"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green.shade50,
      body: FutureBuilder<DocumentSnapshot>(
        future: riderRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("ไม่พบข้อมูลไรเดอร์"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ รูปโปรไฟล์
                if (data['RiderImage'] != null)
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(data['RiderImage']),
                  )
                else
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                const SizedBox(height: 16),

                Text(
                  data['Name'] ?? 'ไม่ทราบชื่อ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "เบอร์โทร: ${data['Phone'] ?? '-'}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const Divider(height: 30, thickness: 1),

                // ✅ รูปยานพาหนะ
                if (data['VehicleImage'] != null)
                  Column(
                    children: [
                      const Text(
                        "รูปยานพาหนะ",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          data['VehicleImage'],
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                _buildInfoTile("หมายเลขยานพาหนะ", data['VehicleNumber']),
                _buildInfoTile(
                    "สร้างเมื่อ",
                    data['createdAt'] != null
                        ? data['createdAt'].toDate().toString()
                        : '-'),
              ],
            ),
          );
        },
      ),

      // ✅ Bottom Navigation Bar
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

  Widget _buildInfoTile(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: Colors.green),
        title: Text(title),
        subtitle: Text(value?.toString() ?? '-'),
      ),
    );
  }
}
