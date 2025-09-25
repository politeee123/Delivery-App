import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  final MapController mapController = MapController();

  MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(16.246373, 103.251827),
        initialZoom: 15.2,
        onTap: (tapPosition, point) {
          log(point.toString());
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.thunderforest.com/mobile-atlas/{z}/{x}/{y}.png?apikey=API_KEY',
          userAgentPackageName: 'net.gonggang.osm_demo',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(16.246373, 103.251827),
              child: Icon(Icons.location_on, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}