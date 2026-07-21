import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ReceiverDeliveryDetailPage extends StatefulWidget {
  final String deliveryId;
  const ReceiverDeliveryDetailPage({super.key, required this.deliveryId});

  @override
  State<ReceiverDeliveryDetailPage> createState() =>
      _ReceiverDeliveryDetailPageState();
}

class _ReceiverDeliveryDetailPageState
    extends State<ReceiverDeliveryDetailPage> {
  @override
  Widget build(BuildContext context) {
    final deliveryRef =
        FirebaseFirestore.instance.collection('delivery').doc(widget.deliveryId);

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("รายละเอียดการจัดส่ง (ผู้รับ)"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: deliveryRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Item')
                .doc(data['product_id'])
                .get(),
            builder: (context, itemSnap) {
              final itemData = itemSnap.data?.data() as Map<String, dynamic>?;

              // 🔹 ดึงข้อมูลผู้ส่ง
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['sender_id'])
                    .get(),
                builder: (context, senderSnap) {
                  final senderData =
                      senderSnap.data?.data() as Map<String, dynamic>?;

                  // 🔹 ดึงข้อมูลพิกัด pickup
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(data['sender_id'])
                        .collection('addresses')
                        .doc(data['pickup_address_id'])
                        .get(),
                    builder: (context, pickupSnap) {
                      final pickupData =
                          pickupSnap.data?.data() as Map<String, dynamic>?;

                      final latitude = pickupData?['lat']?.toDouble();
                      final longitude = pickupData?['lng']?.toDouble();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---------- รูปสินค้า ----------
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  itemData?['Image'] ?? '',
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              "สินค้า: ${itemData?['Item_name'] ?? '-'}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              "สถานะล่าสุด: ${data['status'] ?? '-'}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),

                            // ---------- Card ผู้ส่ง ----------
                            Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.person, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text(
                                          "ข้อมูลผู้ส่ง",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "ชื่อ: ${senderData?['Name'] ?? '-'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "เบอร์โทร: ${senderData?['Phone'] ?? '-'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.blueAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "พิกัดต้นทาง (รับของ)",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (latitude != null && longitude != null)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Latitude: $latitude",
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                          Text(
                                            "Longitude: $longitude",
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            height: 200,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 1,
                                              ),
                                            ),
                                            child: FlutterMap(
                                              options: MapOptions(
                                                initialCenter: LatLng(
                                                    latitude, longitude),
                                                initialZoom: 15,
                                              ),
                                              children: [
                                                TileLayer(
                                                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                                  subdomains: ['a', 'b', 'c', 'd'],
                                                ),
                                                MarkerLayer(
                                                  markers: [
                                                    Marker(
                                                      point: LatLng(
                                                          latitude, longitude),
                                                      width: 60,
                                                      height: 60,
                                                      child: const Icon(
                                                        Icons.location_on,
                                                        size: 40,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      const Text("ไม่มีพิกัด"),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ---------- Card ไรเดอร์ (ใหม่) ----------
                            if (data['rider_id'] != null &&
                                data['rider_id'].toString().isNotEmpty)
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('riders')
                                    .doc(data['rider_id'])
                                    .get(),
                                builder: (context, riderSnap) {
                                  final riderData = riderSnap.data?.data()
                                      as Map<String, dynamic>?;

                                  if (!riderSnap.hasData) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  return Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.motorcycle,
                                                  color: Colors.orange),
                                              SizedBox(width: 8),
                                              Text(
                                                "ข้อมูลไรเดอร์ผู้จัดส่ง",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "ชื่อ: ${riderData?['Name'] ?? '-'}",
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          Text(
                                            "เบอร์โทร: ${riderData?['Phone'] ?? '-'}",
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              const Text(
                                "ยังไม่มีไรเดอร์รับงานนี้",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),

                            const SizedBox(height: 20),
                            const Divider(),

                            // ---------- รูปประกอบสถานะ ----------
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    "📷 รูปประกอบสถานะ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (data['image'] != null &&
                                      data['image'].toString().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        data['image'],
                                        height: 220,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.broken_image,
                                                size: 100),
                                      ),
                                    )
                                  else
                                    const Text("ไม่มีรูปประกอบสถานะ"),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}
