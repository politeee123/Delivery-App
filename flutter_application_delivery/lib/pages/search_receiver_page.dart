import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/create_delivery.dart';

class SearchReceiverPage extends StatefulWidget {
  final String senderId;
  const SearchReceiverPage({super.key, required this.senderId});

  @override
  State<SearchReceiverPage> createState() => _SearchReceiverPageState();
}

class _SearchReceiverPageState extends State<SearchReceiverPage> {
  final phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกผู้รับสินค้า'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ช่องกรอกเบอร์เพื่อค้นหา
            TextField(
              controller: phoneController,
              onChanged: (_) => setState(() {}), // อัปเดตทันทีเมื่อพิมพ์
              decoration: const InputDecoration(
                labelText: 'ค้นหาจากเบอร์โทรศัพท์',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 StreamBuilder โหลดผู้ใช้ทั้งหมด ยกเว้นตัวเอง
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
                  }

                  // แปลงข้อมูลเป็น list
                  final allUsers = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'Name': data['Name'] ?? '',
                      'Phone': data['Phone'] ?? '',
                      'Email': data['Email'] ?? '',
                    };
                  }).toList();

                  // 🔸 กรอง: ไม่เอาตัวเอง + ถ้ามีเบอร์ในช่องค้นหาให้กรอง
                  final filteredUsers = allUsers.where((user) {
                    final isNotSelf = user['id'] != widget.senderId;
                    final search = phoneController.text.trim();
                    if (search.isEmpty) return isNotSelf;
                    return isNotSelf &&
                        (user['Phone'] as String)
                            .toLowerCase()
                            .contains(search.toLowerCase());
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return const Center(child: Text('ไม่พบผู้ใช้ที่ตรงกับเงื่อนไข'));
                  }

                  // 🔹 แสดงรายการผู้ใช้ทั้งหมด (ยกเว้นตัวเอง)
                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.green),
                          title: Text(user['Name']),
                          subtitle: Text(user['Phone']),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateDeliveryPage(
                                  senderId: widget.senderId,
                                  receiverId: user['id'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
