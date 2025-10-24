import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ReceiverDeliveryMapPage extends StatefulWidget {
  final String receiverId;
  const ReceiverDeliveryMapPage({super.key, required this.receiverId});

  @override
  State<ReceiverDeliveryMapPage> createState() =>
      _ReceiverDeliveryMapPageState();
}

class _ReceiverDeliveryMapPageState extends State<ReceiverDeliveryMapPage> {
  final MapController _mapController = MapController();
  String? _receiverName;

  @override
  void initState() {
    super.initState();
    _loadReceiverInfo();
  }

  Future<void> _loadReceiverInfo() async {
    final receiverDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .get();
    setState(() {
      _receiverName = receiverDoc.data()?['Name'] ?? 'ผู้รับ';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แผนที่การจัดส่งถึงฉัน"),
        backgroundColor: Colors.green[600],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('delivery')
            .where('receiver_id', isEqualTo: widget.receiverId)
            .snapshots(),
        builder: (context, deliverySnapshot) {
          if (!deliverySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final deliveries = deliverySnapshot.data!.docs;
          if (deliveries.isEmpty) {
            return const Center(child: Text("ยังไม่มีการจัดส่งมาถึงคุณ"));
          }

          // ✅ ฟังตำแหน่ง Rider แบบ Real-Time
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

  /// ✅ โหลดจุดทั้งหมด (Receiver, Sender, Rider)
  Future<List<Marker>> _buildAllMarkers(
    List<QueryDocumentSnapshot> deliveries,
    List<QueryDocumentSnapshot> riders,
  ) async {
    List<Marker> markers = [];
    Set<String> riderIds = {};

    for (var delivery in deliveries) {
      final data = delivery.data() as Map<String, dynamic>;

      final senderId = data['sender_id'];
      final pickupAddressId = data['pickup_address_id'];
      final dropoffId = data['dropoff_address_id'];
      final riderId = data['rider_id'];

      if (riderId != null) {
        riderIds.add(riderId);
      }

      // 🔹 ดึงชื่อผู้ส่ง
      String senderName = 'ผู้ส่ง';
      if (senderId != null) {
        final senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
        senderName = senderDoc.data()?['Name'] ?? 'ผู้ส่ง';
      }

      // 🔹 จุดผู้ส่ง (Sender)
      if (senderId != null && pickupAddressId != null) {
        final pickupDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
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
                  label: "ผู้ส่ง: $senderName",
                  color: Colors.green,
                ),
              ),
            );
          }
        }
      }

      // 🔹 จุดของผู้รับ (Receiver)
      if (dropoffId != null) {
        final dropDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverId)
            .collection('addresses')
            .doc(dropoffId)
            .get();

        if (dropDoc.exists) {
          final addr = dropDoc.data()!;
          final lat = addr['lat']?.toDouble();
          final lng = addr['lng']?.toDouble();
          if (lat != null && lng != null) {
            markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 120,
                height: 80,
                child: _buildMarker(
                  label: "ฉัน ($_receiverName)",
                  color: Colors.blue,
                ),
              ),
            );
          }
        }
      }
    }

    // 🔹 จุดของ Rider แบบ Real-Time
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

  /// 🎯 Marker UI
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
