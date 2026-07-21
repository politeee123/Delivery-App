import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateDeliveryPage extends StatefulWidget {
  final String senderId;
  final String receiverId;

  const CreateDeliveryPage({
    super.key,
    required this.senderId,
    required this.receiverId,
  });

  @override
  State<CreateDeliveryPage> createState() => _CreateDeliveryPageState();
}

class _CreateDeliveryPageState extends State<CreateDeliveryPage> {
  Map<String, dynamic>? receiverData;
  List<Map<String, dynamic>> receiverAddresses = [];
  List<Map<String, dynamic>> senderAddresses = [];
  String? selectedReceiverAddressId;
  String? selectedSenderAddressId;
  List<Map<String, dynamic>> items = [];
  List<String> selectedItemIds = [];
  File? selectedImage;
  bool isUploading = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    loadReceiverInfo();
    loadSenderAddresses();
    loadItems();
  }

  Future<void> loadReceiverInfo() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .get();

    final addrSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .collection('addresses')
        .get();

    setState(() {
      receiverData = userDoc.data();
      receiverAddresses =
          addrSnap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
    });
  }

  Future<void> loadSenderAddresses() async {
    final addrSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.senderId)
        .collection('addresses')
        .get();

    setState(() {
      senderAddresses =
          addrSnap.docs.map((e) => {...e.data(), 'id': e.id}).toList();
    });
  }

  Future<void> loadItems() async {
    final snap =
        await FirebaseFirestore.instance.collection('Item').limit(20).get();
    setState(() {
      items = snap.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .cast<Map<String, dynamic>>()
          .toList();
    });
  }

  // ✅ ฟังก์ชันถ่ายรูปสินค้า
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  // ✅ อัปโหลดรูปไป Supabase
  Future<String?> uploadToSupabase(File file) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName =
          'delivery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('delivery').upload(fileName, file);
      return supabase.storage.from('delivery').getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Upload failed: $e");
      return null;
    }
  }

  // ✅ ฟังก์ชันสร้างรายการส่ง (บันทึกภาพด้วย)
  Future<void> createDelivery() async {
    if (selectedSenderAddressId == null ||
        selectedReceiverAddressId == null ||
        selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกที่อยู่ผู้ส่ง ผู้รับ และสินค้า')),
      );
      return;
    }

    setState(() => isUploading = true);

    String? imageUrl;
    if (selectedImage != null) {
      imageUrl = await uploadToSupabase(selectedImage!);
    }

    for (final itemId in selectedItemIds) {
      await FirebaseFirestore.instance.collection('delivery').add({
        'sender_id': widget.senderId,
        'receiver_id': widget.receiverId,
        'pickup_address_id': selectedSenderAddressId,
        'dropoff_address_id': selectedReceiverAddressId,
        'product_id': itemId,
        'status': '[1] รอไรเดอร์มารับสินค้า',
        'image': imageUrl, // ✅ บันทึกภาพสินค้าที่ถ่าย
        'created_at': Timestamp.now(),
      });
    }

    setState(() => isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สร้างรายการส่งสินค้าสำเร็จ ✅')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (receiverData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างรายการส่งสินค้า'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 ข้อมูลผู้รับ
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: receiverData!['Image'] != null &&
                          receiverData!['Image'].toString().isNotEmpty
                      ? NetworkImage(receiverData!['Image'])
                      : null,
                  child: receiverData!['Image'] == null ||
                          receiverData!['Image'].toString().isEmpty
                      ? const Icon(Icons.person, color: Colors.grey, size: 40)
                      : null,
                ),
                title: Text(
                  receiverData!['Name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(receiverData!['Phone'] ?? ''),
              ),
            ),

            const Divider(),

            // 🔹 เลือกที่อยู่ผู้ส่ง
            const Text("เลือกที่อยู่ผู้ส่ง:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (senderAddresses.isNotEmpty)
              ...senderAddresses.map((addr) {
                final isSelected = selectedSenderAddressId == addr['id'];
                return Card(
                  color: isSelected ? Colors.green.shade50 : null,
                  child: ListTile(
                    leading: const Icon(Icons.home, color: Colors.green),
                    title: Text(addr['label'] ?? 'ไม่มีชื่อที่อยู่'),
                    subtitle: Text("Lat: ${addr['lat']}  Lng: ${addr['lng']}"),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedSenderAddressId = addr['id'];
                      });
                    },
                  ),
                );
              }).toList()
            else
              const Text("ไม่พบที่อยู่ของผู้ส่ง"),

            const Divider(),

            // 🔹 เลือกที่อยู่ผู้รับ
            const Text("เลือกที่อยู่ผู้รับ:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (receiverAddresses.isNotEmpty)
              ...receiverAddresses.map((addr) {
                final isSelected = selectedReceiverAddressId == addr['id'];
                final double? lat = addr['lat']?.toDouble();
                final double? lng = addr['lng']?.toDouble();

                return Column(
                  children: [
                    Card(
                      color: isSelected ? Colors.green.shade50 : null,
                      child: ListTile(
                        leading: const Icon(Icons.location_on,
                            color: Colors.green),
                        title: Text(addr['label'] ?? 'ไม่มีชื่อที่อยู่'),
                        subtitle:
                            Text("Lat: ${addr['lat']}  Lng: ${addr['lng']}"),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            selectedReceiverAddressId = addr['id'];
                          });
                        },
                      ),
                    ),
                    if (isSelected && lat != null && lng != null)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                subdomains: ['a', 'b', 'c', 'd'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lng),
                                    width: 60,
                                    height: 60,
                                    child: const Icon(Icons.location_on,
                                        size: 40, color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }).toList()
            else
              const Text("ไม่พบที่อยู่ของผู้รับ"),

            const Divider(),

            // 🔹 เลือกสินค้า
            const Text("เลือกสินค้าที่จะจัดส่ง:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ...items.map((item) {
              final isSelected = selectedItemIds.contains(item['id']);
              return Card(
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedItemIds.add(item['id']);
                      } else {
                        selectedItemIds.remove(item['id']);
                      }
                    });
                  },
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item['Image'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.image, size: 60),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['Item_name'] ?? 'ไม่มีชื่อสินค้า',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
            const Text("ถ่ายภาพสินค้าก่อนส่ง:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 🔹 แสดงภาพที่ถ่าย (หรือปุ่มถ่ายใหม่)
            Center(
              child: Column(
                children: [
                  if (selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        selectedImage!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("ถ่ายภาพสินค้า"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                onPressed: isUploading ? null : createDelivery,
                icon: const Icon(Icons.local_shipping),
                label: isUploading
                    ? const Text('กำลังอัปโหลด...')
                    : const Text('ยืนยันสร้างรายการส่ง'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
