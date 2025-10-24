import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/delivery_map_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RiderDeliveryDetail extends StatefulWidget {
  final String deliveryId;
  final String riderId;

  const RiderDeliveryDetail({
    super.key,
    required this.deliveryId,
    required this.riderId,
  });

  @override
  State<RiderDeliveryDetail> createState() => _RiderDeliveryDetailState();
}

class _RiderDeliveryDetailState extends State<RiderDeliveryDetail> {
  Map<String, dynamic>? deliveryData;
  Map<String, dynamic>? senderData;
  Map<String, dynamic>? receiverData;
  Map<String, dynamic>? pickupAddressData;
  Map<String, dynamic>? dropoffAddressData;
  Map<String, dynamic>? productData;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    final deliveryDoc = await FirebaseFirestore.instance
        .collection('delivery')
        .doc(widget.deliveryId)
        .get();

    if (!deliveryDoc.exists) return;

    final data = deliveryDoc.data()!;
    final senderId = data['sender_id'];
    final receiverId = data['receiver_id'];
    final pickupId = data['pickup_address_id'];
    final dropoffId = data['dropoff_address_id'];
    final productId = data['product_id'];

    final senderDoc =
        await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    final receiverDoc =
        await FirebaseFirestore.instance.collection('users').doc(receiverId).get();

    final pickupDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .collection('addresses')
        .doc(pickupId)
        .get();

    final dropoffDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverId)
        .collection('addresses')
        .doc(dropoffId)
        .get();

    final productDoc =
        await FirebaseFirestore.instance.collection('Item').doc(productId).get();

    setState(() {
      deliveryData = data;
      senderData = senderDoc.data();
      receiverData = receiverDoc.data();
      pickupAddressData = pickupDoc.data();
      dropoffAddressData = dropoffDoc.data();
      productData = productDoc.data();
    });
  }

  Future<void> acceptJob() async {
  final docRef =
      FirebaseFirestore.instance.collection('delivery').doc(widget.deliveryId);
  final snapshot = await docRef.get();
  if (!snapshot.exists) return;

  if (snapshot['status'] != '[1] รอไรเดอร์มารับสินค้า') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('งานนี้มีไรเดอร์รับไปแล้ว')),
    );
    return;
  }

  // ✅ อัปเดตสถานะ + rider_id ลงใน document delivery
  await docRef.update({
    'status': '[2] ไรเดอร์รับสินค้าแล้ว',
    'rider_id': widget.riderId,
  });

  // ✅ แสดงข้อความสำเร็จ
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('รับงานเรียบร้อยแล้ว! ✅')),
  );

  // ✅ เมื่อรับงานแล้ว ไปหน้าแผนที่แสดงตำแหน่งไรเดอร์แบบเรียลไทม์
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => DeliveryMapPage(
        riderId: widget.riderId,
        deliveryId: widget.deliveryId,
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    if (deliveryData == null ||
        senderData == null ||
        receiverData == null ||
        pickupAddressData == null ||
        dropoffAddressData == null ||
        productData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double pickupLat = pickupAddressData!['lat']?.toDouble() ?? 0;
    final double pickupLng = pickupAddressData!['lng']?.toDouble() ?? 0;

    final double dropoffLat = dropoffAddressData!['lat']?.toDouble() ?? 0;
    final double dropoffLng = dropoffAddressData!['lng']?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('รายละเอียดการจัดส่ง'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔸 Section: ผู้ส่ง
            _sectionHeader(Icons.store, 'ข้อมูลผู้ส่ง', Colors.orange),
            _infoCard(
              title: senderData!['Name'] ?? 'ไม่พบชื่อผู้ส่ง',
              subtitle: senderData!['Phone'] ?? '',
              icon: Icons.person,
              iconColor: Colors.green,
            ),
            _addressCard(
              title: 'ที่อยู่เพื่อรับสินค้า',
              lat: pickupLat,
              lng: pickupLng,
              color: Colors.orange,
            ),
            _miniMap(pickupLat, pickupLng, Colors.orange, Icons.store),

            const SizedBox(height: 20),

            // 🔸 Section: ผู้รับ
            _sectionHeader(Icons.local_shipping, 'ข้อมูลผู้รับ', Colors.blue),
            _infoCard(
              title: receiverData!['Name'] ?? 'ไม่พบชื่อผู้รับ',
              subtitle: receiverData!['Phone'] ?? '',
              icon: Icons.person_pin_circle,
              iconColor: Colors.blue,
            ),
            _addressCard(
              title: 'ที่อยู่เพื่อส่งสินค้า',
              lat: dropoffLat,
              lng: dropoffLng,
              color: Colors.red,
            ),
            _miniMap(dropoffLat, dropoffLng, Colors.red, Icons.location_on),

            const SizedBox(height: 20),

            // 🔸 Section: สินค้า
            _sectionHeader(Icons.inventory, 'รายละเอียดสินค้า', Colors.green),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: productData!['Image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          productData!['Image'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.image, size: 60, color: Colors.grey),
                title: Text(
                  productData!['Item_name'] ?? 'ไม่มีชื่อสินค้า',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    Text(productData!['Desciption'] ?? 'ไม่มีรายละเอียดสินค้า'),
              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: acceptJob,
                icon: const Icon(Icons.check, size: 22),
                label: const Text(
                  "รับงานนี้",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ 🔹 Helper Widgets ------------------

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _addressCard({
    required String title,
    required double lat,
    required double lng,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.location_on, color: color),
        title: Text(title),
        subtitle: Text('Lat: $lat\nLng: $lng'),
      ),
    );
  }

  Widget _miniMap(double lat, double lng, Color color, IconData icon) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 50,
                height: 50,
                child: Icon(icon, color: color, size: 40),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
