import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _deliveryData;

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
      });

      // ดึงตำแหน่ง sender address จาก users/{senderId}/addresses/{pickup_address_id}
      if (data['sender_id'] != null && data['pickup_address_id'] != null) {
        _loadSenderAddress(
          data['sender_id'],
          data['pickup_address_id'],
        );
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
      final lat = data['lat']?.toDouble();
      final lng = data['lng']?.toDouble();

      if (lat != null && lng != null) {
        setState(() {
          _senderLatLng = LatLng(lat, lng);
        });
      }
    }
  }

  /// ✅ ติดตามตำแหน่งไรเดอร์แบบเรียลไทม์
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเปิด GPS')));
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง')));
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

      _mapController.move(LatLng(position.latitude, position.longitude), 16);
    });
  }

  /// ✅ ถ่ายรูปและอัปโหลดสถานะ 3
  Future<void> _capturePickupImage() async {
    if (_currentLatLng == null || _senderLatLng == null) return;

    final distance = Geolocator.distanceBetween(
      _senderLatLng!.latitude,
      _senderLatLng!.longitude,
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
    );

    if (distance > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('คุณอยู่ห่างจากจุดรับสินค้ามากกว่า 20 เมตร')),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    try {
      final supabase = Supabase.instance.client;
      final file = File(image.path);
      final fileName = 'pickup_${widget.deliveryId}.jpg';

      await supabase.storage
          .from('deliveries')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final imageUrl =
          supabase.storage.from('deliveries').getPublicUrl(fileName);

      await FirebaseFirestore.instance
          .collection('delivery')
          .doc(widget.deliveryId)
          .update({
        'status': '[3] ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง',
        'pickupImage': imageUrl,
        'pickupAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกสถานะรับสินค้าเรียบร้อย ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
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
                    MarkerLayer(markers: [
                      // 🔴 ไรเดอร์
                      Marker(
                        point: _currentLatLng!,
                        width: 60,
                        height: 60,
                        child: const Icon(
                          Icons.motorcycle,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                      // 🟢 จุดรับของ sender
                      if (_senderLatLng != null)
                        Marker(
                          point: _senderLatLng!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.blue,
                            size: 45,
                          ),
                        ),
                    ]),
                  ],
                ),

                // 📸 ปุ่มถ่ายรูปสถานะ 3
                Positioned(
                  bottom: 30,
                  left: 30,
                  right: 30,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _capturePickupImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      "ถ่ายรูปเมื่อถึงจุดรับสินค้า",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
