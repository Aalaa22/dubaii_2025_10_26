import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMap extends StatelessWidget {
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? markerTitle;
  final double? height;
  final bool openOnTap;

  const LocationMap({
    super.key,
    this.address,
    this.latitude,
    this.longitude,
    this.markerTitle,
    this.height,
    this.openOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng target = LatLng(latitude ?? 25.2048, longitude ?? 55.2708);
    final double mapHeight = height ?? 188.h;

    return Container(
      height: mapHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 14.0),
          markers: {
            Marker(
              markerId: const MarkerId('location_marker'),
              position: target,
              infoWindow: InfoWindow(
                title: markerTitle,
                snippet: address ?? '',
              ),
            ),
          },
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          onTap: (LatLng _) {
            if (!openOnTap) return;
            final String query = (address ?? '').trim();
            final Uri uri = query.isNotEmpty
                ? Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}')
                : Uri.parse('https://www.google.com/maps/search/?api=1&query=${target.latitude},${target.longitude}');
            _launch(uri);
          },
        ),
      ),
    );
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback to in-app webview if external app fails
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }
}