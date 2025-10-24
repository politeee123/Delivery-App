import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/home_rider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryMapPage extends StatefulWidget {
  final String riderId;
  final String deliveryId;

  const DeliveryMapPage({
    super.key,
    required this.riderId,
    required this.deliveryId,
  });

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  LatLng? _currentLatLng;
  LatLng? _senderLatLng;
  LatLng? _receiverLatLng;
  Map<String, dynamic>? _deliveryData;
  bool isPickupDone = false; // ✅ ใช้เช็คว่าถ่ายรูปสถานะ 3 แล้วหรือยัง

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// ✅ โหลดข้อมูลการจัดส่ง
  Future<void> _loadDeliveryData() async {
    final doc = await FirebaseFirestore.instance
        .collection('delivery')
        .doc(widget.deliveryId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _deliveryData = data;
        isPickupDone = data['status']
            .toString()
            .contains('กำลังเดินทางไปส่ง'); // ถ้าเป็นสถานะ 3 แล้วถือว่าถ่ายรูปแล้ว
      });

      // ดึงจุด sender และ receiver
      if (data['sender_id'] != null && data['pickup_address_id'] != null) {
        _loadSenderAddress(data['sender_id'], data['pickup_address_id']);
      }
      if (data['receiver_id'] != null && data['dropoff_address_id'] != null) {
        _loadReceiverAddress(data['receiver_id'], data['dropoff_address_id']);
      }
    }
  }

  /// ✅ โหลดที่อยู่ sender
  Future<void> _loadSenderAddress(String senderId, String addressId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .collection('addresses')
        .doc(addressId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _senderLatLng = LatLng(data['lat'].toDouble(), data['lng'].toDouble());
      });
    }
  }

  /// ✅ โหลดที่อยู่ receiver
  Future<void> _loadReceiverAddress(String receiverId, String addressId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('addresses')
        .doc(addressId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _receiverLatLng = LatLng(data['lat'].toDouble(), data['lng'].toDouble());
      });
    }
  }

  /// ✅ ติดตามตำแหน่งไรเดอร์แบบเรียลไทม์
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเปิด GPS')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง')),
      );
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });

      await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.riderId)
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _mapController.move(LatLng(position.latitude, position.longitude), 16);
      }
    });
  }

  /// ✅ ฟังก์ชันอัปโหลดรูปขึ้น Supabase
  Future<String?> uploadToSupabase(File file) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'delivery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('delivery').upload(fileName, file);
      return supabase.storage.from('delivery').getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Upload failed: $e");
      return null;
    }
  }

  /// ✅ ถ่ายรูปสถานะ 3 หรือ 4 (แบบเดียวกัน)
  Future<void> _captureImage() async {
    if (_currentLatLng == null) return;

    // จุดเป้าหมาย (sender หรือ receiver)
    final target = isPickupDone ? _receiverLatLng : _senderLatLng;
    if (target == null) return;

    final distance = Geolocator.distanceBetween(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      target.latitude,
      target.longitude,
    );

    if (distance > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPickupDone
              ? 'คุณยังไม่ถึงจุดผู้รับ (ห่าง ${distance.toStringAsFixed(1)} เมตร)'
              : 'คุณยังไม่ถึงจุดรับสินค้า (ห่าง ${distance.toStringAsFixed(1)} เมตร)'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    try {
      final file = File(image.path);
      final imageUrl = await uploadToSupabase(file);

      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ ❌')),
        );
        return;
      }

      if (!isPickupDone) {
        // 📦 สถานะ 3
        await FirebaseFirestore.instance
            .collection('delivery')
            .doc(widget.deliveryId)
            .update({
          'status': '[3] ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง',
          'image': imageUrl,
          'pickupAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          isPickupDone = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รับสินค้าสำเร็จ ✅')),
        );
      } else {
        // 🎯 สถานะ 4
        await FirebaseFirestore.instance
            .collection('delivery')
            .doc(widget.deliveryId)
            .update({
          'status': '[4] ส่งสำเร็จแล้ว',
          'image': imageUrl,
          'deliveredAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งสินค้าสำเร็จ ✅')),
        );

        // กลับไปหน้า HomeRider
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) => HomeRider(riderId: widget.riderId)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ติดตามการจัดส่ง"),
        backgroundColor: Colors.green,
      ),
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLatLng!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLatLng!,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.motorcycle,
                              color: Colors.red, size: 50),
                        ),
                        if (!isPickupDone && _senderLatLng != null)
                          Marker(
                            point: _senderLatLng!,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.store,
                                color: Colors.blue, size: 45),
                          ),
                        if (isPickupDone && _receiverLatLng != null)
                          Marker(
                            point: _receiverLatLng!,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_pin,
                                color: Colors.green, size: 45),
                          ),
                      ],
                    ),
                  ],
                ),

                // 📸 ปุ่มถ่ายรูป
                Positioned(
                  bottom: 30,
                  left: 30,
                  right: 30,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPickupDone ? Colors.orange : Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      isPickupDone
                          ? "ถ่ายรูปเมื่อถึงผู้รับ"
                          : "ถ่ายรูปเมื่อถึงจุดรับสินค้า",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
