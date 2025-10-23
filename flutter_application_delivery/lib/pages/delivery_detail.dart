import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DeliveryDetailPage extends StatefulWidget {
  final String deliveryId;
  const DeliveryDetailPage({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  @override
  Widget build(BuildContext context) {
    final deliveryRef =
        FirebaseFirestore.instance.collection('delivery').doc(widget.deliveryId);

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("รายละเอียดการจัดส่ง"),
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

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['receiver_id'])
                    .get(),
                builder: (context, receiverSnap) {
                  final receiverData =
                      receiverSnap.data?.data() as Map<String, dynamic>?;

                  // 📍 ดึงข้อมูลพิกัด dropoff
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(data['receiver_id'])
                        .collection('addresses')
                        .doc(data['dropoff_address_id'])
                        .get(),
                    builder: (context, dropSnap) {
                      final dropData =
                          dropSnap.data?.data() as Map<String, dynamic>?;

                      final latitude = dropData?['lat']?.toDouble();
                      final longitude = dropData?['lng']?.toDouble();

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

                            // ---------- Card ผู้รับ + พิกัด ----------
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
                                          "ข้อมูลผู้รับ",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "ชื่อ: ${receiverData?['Name'] ?? '-'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      "เบอร์โทร: ${receiverData?['Phone'] ?? '-'}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "พิกัดที่อยู่จัดส่ง",
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
                                          // ✅ แผนที่ย่อ
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
                                                  urlTemplate:
                                                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                  subdomains: const [
                                                    'a',
                                                    'b',
                                                    'c'
                                                  ],
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
                                                        color: Colors.red,
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
