import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationProfilePage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? addressName;

  const LocationProfilePage({
    super.key,
    required this.latitude,
    required this.longitude,
    this.addressName,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng position = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(addressName != null
            ? "ตำแหน่งของ $addressName"
            : "ตำแหน่งที่อยู่"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: position,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: position,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_on,
                  size: 45,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
