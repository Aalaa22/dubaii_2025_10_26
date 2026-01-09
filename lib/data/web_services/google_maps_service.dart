import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:advertising_app/data/web_services/google_api_service.dart';
// import 'package:geolocator/geolocator.dart'; // Temporarily disabled

class GoogleMapsService {
  final GoogleApiService _googleApiService;

  GoogleMapsService(this._googleApiService);

  GoogleMapController? _mapController;

  // Initialize map controller
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  // Get current location - TEMPORARILY DISABLED
  /*
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }
  */
  
  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // تنظيف العنوان وإزالة الرموز الغريبة
        String street = place.street ?? '';
        String locality = place.locality ?? '';
        String country = place.country ?? '';
        
        // تنظيف العنوان الكامل من الرموز الغريبة
        String fullAddress = '${street}, ${locality}, ${country}';
        String cleanedAddress = _cleanAddress(fullAddress);
        
        return cleanedAddress.isNotEmpty ? cleanedAddress : '${locality}, ${country}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }
  
  // دالة لتنظيف العنوان من الرموز الغريبة
   String _cleanAddress(String address) {
     // إزالة الرموز مثل J77R+357 أو أي رمز يحتوي على أرقام ورموز غريبة
     String cleanedAddress = address
         .replaceAll(RegExp(r'[A-Z0-9]+\+[0-9]+،?\s*'), '') // إزالة رموز مثل J77R+357
         .replaceAll(RegExp(r'^[A-Z0-9]+،?\s*'), '') // إزالة الرموز في بداية النص
         .replaceAll(RegExp(r'،\s*،'), '،') // إزالة الفواصل المتكررة
         .replaceAll(RegExp(r'^،\s*'), '') // إزالة الفاصلة في البداية
         .replaceAll(RegExp(r'،\s*$'), '') // إزالة الفاصلة في النهاية
         .trim();
     
     return cleanedAddress;
   }
  
  // Get coordinates from address
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }
  
  // Move camera to specific location
  Future<void> moveCameraToLocation(double latitude, double longitude, {double zoom = 15.0}) async {
    try {
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: zoom,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error moving camera: $e');
      // Silently fail - camera movement is not critical for location functionality
    }
  }
  
  // Create marker
  Marker createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
    );
  }
  
  // Calculate distance between two points - TEMPORARILY DISABLED
  /*
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
  */
  
  // Temporary replacement for distance calculation
  double calculateDistance(LatLng point1, LatLng point2) {
    // Simple approximation - replace with proper calculation later
    return 0.0;
  }
  
  // Dispose resources
  void dispose() {
    _mapController?.dispose();
  }
}