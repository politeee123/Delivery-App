import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_rider.dart'; // กลับไปหน้านี้หลังส่งของ

class DeliveryToReceiverPage extends StatefulWidget {
  final String riderId;
  final String deliveryId;

  const DeliveryToReceiverPage({
    super.key,
    required this.riderId,
    required this.deliveryId,
  });

  @override
  State<DeliveryToReceiverPage> createState() => _DeliveryToReceiverPageState();
}

class _DeliveryToReceiverPageState extends State<DeliveryToReceiverPage> {
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  LatLng? _currentLatLng;
  LatLng? _receiverLatLng;
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

      // โหลดที่อยู่ receiver
      if (data['receiver_id'] != null && data['dropoff_address_id'] != null) {
        _loadReceiverAddress(data['receiver_id'], data['dropoff_address_id']);
      }
    }
  }

  Future<void> _loadReceiverAddress(String receiverId, String addressId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('addresses')
        .doc(addressId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final lat = data['lat']?.toDouble();
      final lng = data['lng']?.toDouble();

      if (lat != null && lng != null) {
        setState(() {
          _receiverLatLng = LatLng(lat, lng);
        });
      }
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

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

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16,
      );
    });
  }

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

  /// ✅ ถ่ายรูปเมื่อถึงจุดส่งของ
  Future<void> _captureDeliveryImage() async {
    if (_currentLatLng == null || _receiverLatLng == null) return;

    final distance = Geolocator.distanceBetween(
      _receiverLatLng!.latitude,
      _receiverLatLng!.longitude,
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
    );

    if (distance > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณอยู่ห่างจากจุดส่งสินค้ามากกว่า 20 เมตร')),
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

      await FirebaseFirestore.instance
          .collection('delivery')
          .doc(widget.deliveryId)
          .update({
        'status': '[4] ส่งสินค้าเรียบร้อยแล้ว ✅',
        'image': imageUrl,
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งสินค้าสำเร็จ ✅')),
      );

      // ✅ กลับไปหน้า "รับงาน"
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeRider(riderId: widget.riderId),
        ),
        (route) => false,
      );
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
        title: const Text("ติดตามสถานะ 4: ส่งสินค้า"),
        backgroundColor: Colors.orange,
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
                          child: const Icon(
                            Icons.motorcycle,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                        if (_receiverLatLng != null)
                          Marker(
                            point: _receiverLatLng!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.green,
                              size: 45,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 30,
                  left: 30,
                  right: 30,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _captureDeliveryImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      "ถ่ายรูปเมื่อถึงจุดส่งของ",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
