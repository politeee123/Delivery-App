import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateDeliveryPage extends StatefulWidget {
  final String senderId;
  const CreateDeliveryPage({super.key, required this.senderId});

  @override
  State<CreateDeliveryPage> createState() => _CreateDeliveryPageState();
}

class _CreateDeliveryPageState extends State<CreateDeliveryPage> {
  final phoneController = TextEditingController();
  Map<String, dynamic>? receiverData;
  List<Map<String, dynamic>> receiverAddresses = [];
  String? selectedAddressId;
  List<String> selectedProducts = [];

  final sampleProducts = [
    "สินค้า 1 - โทรศัพท์",
    "สินค้า 2 - กล่องขนาดเล็ก",
    "สินค้า 3 - เอกสาร",
    "สินค้า 4 - เสื้อผ้า",
    "สินค้า 5 - ของใช้ทั่วไป",
  ];

  /// 🔍 ค้นหาผู้รับจากเบอร์โทร และโหลดที่อยู่ทั้งหมด
  Future<void> searchReceiver() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('Phone', isEqualTo: phoneController.text)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final userData = snap.docs.first.data();
      final userId = snap.docs.first.id;

      // โหลดที่อยู่ของผู้รับ
      final addrSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      setState(() {
        receiverData = {...userData, 'user_id': userId};
        receiverAddresses =
            addrSnap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบผู้ใช้จากเบอร์โทรนี้')),
      );
    }
  }

  /// 🚚 สร้างรายการส่ง
  Future<void> createDelivery() async {
    if (receiverData == null ||
        selectedAddressId == null ||
        selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('delivery').add({
      'sender_id': widget.senderId,
      'receiver_id': receiverData!['user_id'],
      'dropoff_address_id': selectedAddressId,
      'products': selectedProducts,
      'status': 'pending',
      'created_at': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สร้างรายการส่งสำเร็จ')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างรายการส่งสินค้า')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 ช่องค้นหาผู้รับ
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'เบอร์โทรผู้รับ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchReceiver,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 แสดงข้อมูลผู้รับ
            if (receiverData != null) ...[
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(receiverData!['Name'] ?? ''),
                subtitle: Text(receiverData!['Phone'] ?? ''),
              ),
              const Divider(),

              const Text("เลือกที่อยู่ผู้รับ:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // 🔹 แสดงที่อยู่ทั้งหมดของผู้รับ
              if (receiverAddresses.isNotEmpty)
                ...receiverAddresses.map((addr) {
                  final isSelected = selectedAddressId == addr['id'];
                  return Card(
                    color: isSelected ? Colors.green.shade50 : null,
                    child: ListTile(
                      leading: const Icon(Icons.home, color: Colors.green),
                      title: Text(addr['label'] ?? 'ไม่มีชื่อที่อยู่'),
                      subtitle: Text(
                          "Lat: ${addr['lat']}\nLng: ${addr['lng']}"),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          selectedAddressId = addr['id'];
                        });
                      },
                    ),
                  );
                }).toList()
              else
                const Text("ไม่พบที่อยู่ของผู้รับ"),

              const SizedBox(height: 16),
              const Divider(),

              // 🔹 เลือกสินค้า
              const Text("เลือกสินค้าที่จะจัดส่ง:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ...sampleProducts.map((p) {
                final isSelected = selectedProducts.contains(p);
                return CheckboxListTile(
                  title: Text(p),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedProducts.add(p);
                      } else {
                        selectedProducts.remove(p);
                      }
                    });
                  },
                );
              }).toList(),

              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: createDelivery,
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('ยืนยันสร้างรายการส่ง'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
