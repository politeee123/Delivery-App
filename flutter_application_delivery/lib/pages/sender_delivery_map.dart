import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SenderDeliveryMapPage extends StatefulWidget {
  final String senderId;
  const SenderDeliveryMapPage({super.key, required this.senderId});

  @override
  State<SenderDeliveryMapPage> createState() => _SenderDeliveryMapPageState();
}

class _SenderDeliveryMapPageState extends State<SenderDeliveryMapPage> {
  final MapController _mapController = MapController();
  String? _senderName;

  @override
  void initState() {
    super.initState();
    _loadSenderInfo();
  }

  Future<void> _loadSenderInfo() async {
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.senderId)
        .get();
    setState(() {
      _senderName = senderDoc.data()?['Name'] ?? 'ผู้ส่ง';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แผนที่การจัดส่งทั้งหมด"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('delivery')
            .where('sender_id', isEqualTo: widget.senderId)
            .snapshots(),
        builder: (context, deliverySnapshot) {
          if (!deliverySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final deliveries = deliverySnapshot.data!.docs;
          if (deliveries.isEmpty) {
            return const Center(child: Text("ยังไม่มีการจัดส่ง"));
          }

          // ✅ ใช้ StreamBuilder ซ้อนอีกตัว เพื่อให้ตำแหน่ง Rider อัปเดตแบบ real-time
          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('riders').snapshots(),
            builder: (context, riderSnapshot) {
              if (!riderSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final riders = riderSnapshot.data!.docs;
              return FutureBuilder<List<Marker>>(
                future: _buildAllMarkers(deliveries, riders),
                builder: (context, markerSnapshot) {
                  if (!markerSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final markers = markerSnapshot.data!;
                  if (markers.isEmpty) {
                    return const Center(child: Text("ไม่พบตำแหน่งบนแผนที่"));
                  }

                  final center = markers.first.point;
                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ โหลดจุดทั้งหมด (Sender, Receiver, Rider แบบ realtime)
  Future<List<Marker>> _buildAllMarkers(
    List<QueryDocumentSnapshot> deliveries,
    List<QueryDocumentSnapshot> riders,
  ) async {
    List<Marker> markers = [];
    Set<String> riderIds = {};

    for (var delivery in deliveries) {
      final data = delivery.data() as Map<String, dynamic>;

      final receiverId = data['receiver_id'];
      final pickupAddressId = data['pickup_address_id'];
      final dropoffId = data['dropoff_address_id'];
      final riderId = data['rider_id'];

      if (riderId != null) {
        riderIds.add(riderId);
      }

      // 🔹 ชื่อผู้รับ
      String receiverName = 'ผู้รับ';
      if (receiverId != null) {
        final receiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
        receiverName = receiverDoc.data()?['Name'] ?? 'ผู้รับ';
      }

      // 🔹 จุดรับ (Sender)
      if (pickupAddressId != null) {
        final pickupDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.senderId)
            .collection('addresses')
            .doc(pickupAddressId)
            .get();

        if (pickupDoc.exists) {
          final addr = pickupDoc.data()!;
          final lat = addr['lat']?.toDouble();
          final lng = addr['lng']?.toDouble();
          if (lat != null && lng != null) {
            markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 120,
                height: 80,
                child: _buildMarker(
                  label: "ส่งให้: $receiverName",
                  color: Colors.green,
                ),
              ),
            );
          }
        }
      }

      // 🔹 จุดปลายทาง (Receiver)
      if (receiverId != null && dropoffId != null) {
        final addrDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .collection('addresses')
            .doc(dropoffId)
            .get();

        if (addrDoc.exists) {
          final addr = addrDoc.data()!;
          final lat = addr['lat']?.toDouble();
          final lng = addr['lng']?.toDouble();
          if (lat != null && lng != null) {
            markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 120,
                height: 80,
                child: _buildMarker(
                  label: "ได้รับจาก: $_senderName",
                  color: Colors.blue,
                ),
              ),
            );
          }
        }
      }
    }

    // 🔹 Rider markers แบบ real-time
    for (var rider in riders) {
      final riderData = rider.data() as Map<String, dynamic>;
      if (riderIds.contains(rider.id)) {
        final lat = riderData['latitude']?.toDouble();
        final lng = riderData['longitude']?.toDouble();
        final name = riderData['Name'] ?? 'Rider';
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 120,
              height: 80,
              child: _buildMarker(
                label: "Rider: $name",
                color: Colors.red,
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  /// 🎯 Marker แบบเรียบง่าย
  Widget _buildMarker({
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(Icons.location_on, color: color, size: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
    
      ],
    );
  }
}
