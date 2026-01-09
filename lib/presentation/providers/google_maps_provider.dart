import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
// import 'package:geolocator/geolocator.dart'; // Temporarily disabled
import '../../data/web_services/google_maps_service.dart';
import '../../data/web_services/location_service.dart';

class GoogleMapsProvider extends ChangeNotifier {
  final GoogleMapsService _mapsService;
  final LocationService _locationService = LocationService();

  GoogleMapsProvider(this._mapsService);

  GoogleMapController? _mapController;
  // Position? _currentPosition; // Temporarily disabled
  LocationData? _currentLocationData;
  Set<Marker> _markers = {};
  String? _currentAddress;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  GoogleMapController? get mapController => _mapController;
  // Position? get currentPosition => _currentPosition; // Temporarily disabled
  LocationData? get currentLocationData => _currentLocationData;
  Set<Marker> get markers => _markers;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Initialize map
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapsService.onMapCreated(controller);
    notifyListeners();
  }
  
  // Get current location - TEMPORARILY DISABLED
  /*
  Future<void> getCurrentLocation() async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentPosition = await _mapsService.getCurrentLocation();
      _currentLocationData = await _locationService.getCurrentLocationData();
      
      if (_currentPosition != null) {
        // Get address for current location
        _currentAddress = await _mapsService.getAddressFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        
        // Move camera to current location
        await _mapsService.moveCameraToLocation(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        
        // Add marker for current location
        addMarker(
          'current_location',
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          title: 'موقعي الحالي',
          snippet: _currentAddress,
        );
      }
    } catch (e) {
      _setError('خطأ في الحصول على الموقع الحالي: $e');
    } finally {
      _setLoading(false);
    }
  }
  */
  
  // Temporary replacement for getCurrentLocation
  Future<void> getCurrentLocation() async {
    _setLoading(true);
    _clearError();
    
    try {
      // print('GoogleMapsProvider: Starting location request...');
      _currentLocationData = await _locationService.getCurrentLocationData();
      
      if (_currentLocationData != null) {
        // print('GoogleMapsProvider: Location data received successfully');
        
        // Get address for current location
        _currentAddress = await _mapsService.getAddressFromCoordinates(
          _currentLocationData!.latitude!,
          _currentLocationData!.longitude!,
        );
        
        // print('GoogleMapsProvider: Address resolved: $_currentAddress');
        
        // Move camera to current location
        await _mapsService.moveCameraToLocation(
          _currentLocationData!.latitude!,
          _currentLocationData!.longitude!,
        );
        
        // Add marker for current location
        addMarker(
          'current_location',
          LatLng(_currentLocationData!.latitude!, _currentLocationData!.longitude!),
          title: 'موقعي الحالي',
          snippet: _currentAddress,
        );
        
        // print('GoogleMapsProvider: Location process completed successfully');
      } else {
        throw Exception('فشل في الحصول على بيانات الموقع - لم يتم إرجاع أي بيانات');
      }
    } catch (e) {
      // print('GoogleMapsProvider: Error occurred: $e');
      String errorMessage = e.toString();
      
      // Handle specific error messages with more helpful instructions
      if (errorMessage.contains('خدمة الموقع غير مفعلة')) {
        _setError('خدمة الموقع غير مفعلة\n\nللحل:\n• في Chrome: اضغط على أيقونة القفل بجانب العنوان واختر "السماح" للموقع\n• في Firefox: اضغط على أيقونة الدرع واختر "إيقاف الحماية"\n• تأكد من تفعيل خدمة الموقع في إعدادات الجهاز');
      } else if (errorMessage.contains('تم رفض إذن الوصول للموقع')) {
        _setError('تم رفض إذن الوصول للموقع\n\nللحل:\n• اضغط على أيقونة القفل/الموقع بجانب عنوان الموقع\n• اختر "السماح" أو "Allow" للوصول للموقع\n• أعد تحميل الصفحة وحاول مرة أخرى');
      } else if (errorMessage.contains('انتهت مهلة الحصول على الموقع')) {
        _setError('انتهت مهلة الحصول على الموقع\n\nللحل:\n• تأكد من اتصالك بالإنترنت\n• تأكد من تفعيل خدمة الموقع\n• حاول مرة أخرى بعد قليل');
      } else if (errorMessage.contains('خطأ في النظام')) {
        _setError('خطأ في النظام\n\nللحل:\n• تأكد من تفعيل خدمة الموقع في المتصفح\n• امنح الإذن للموقع للوصول لموقعك\n• جرب متصفح آخر إذا استمرت المشكلة');
      } else {
        _setError('خطأ في الحصول على الموقع\n\nتفاصيل الخطأ: $errorMessage\n\nللحل:\n• تأكد من تفعيل خدمة الموقع\n• امنح الإذن للموقع\n• تأكد من اتصالك بالإنترنت');
      }
      rethrow; // Re-throw to allow calling code to handle the error
    } finally {
      _setLoading(false);
    }
  }
  
  // Add marker
  void addMarker(
    String markerId,
    LatLng position, {
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
  }) {
    final marker = _mapsService.createMarker(
      markerId: markerId,
      position: position,
      title: title,
      snippet: snippet,
      icon: icon,
      onTap: onTap,
    );
    
    _markers.add(marker);
    notifyListeners();
  }
  
  // Remove marker
  void removeMarker(String markerId) {
    _markers.removeWhere((marker) => marker.markerId.value == markerId);
    notifyListeners();
  }
  
  // Clear all markers
  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }
  
  // Move camera to location
  Future<void> moveCameraToLocation(double latitude, double longitude, {double zoom = 15.0}) async {
    await _mapsService.moveCameraToLocation(latitude, longitude, zoom: zoom);
  }
  
  // Search location by address
  Future<void> searchLocationByAddress(String address) async {
    _setLoading(true);
    _clearError();
    
    try {
      final location = await _mapsService.getCoordinatesFromAddress(address);
      if (location != null) {
        await moveCameraToLocation(location.latitude, location.longitude);
        
        // Add marker for searched location
        addMarker(
          'searched_location',
          LatLng(location.latitude, location.longitude),
          title: 'الموقع المبحوث عنه',
          snippet: address,
        );
      } else {
        _setError('لم يتم العثور على الموقع');
      }
    } catch (e) {
      _setError('خطأ في البحث عن الموقع: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    return await _mapsService.getAddressFromCoordinates(latitude, longitude);
  }
  
  // Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return _mapsService.calculateDistance(point1, point2);
  }
  
  // Format distance for display
  String formatDistance(double distanceInMeters) {
    return _locationService.formatDistance(distanceInMeters);
  }
  
  // Handle map tap
  void onMapTap(LatLng position) async {
    // Remove previous tap marker
    removeMarker('tap_location');
    
    // Get address for tapped location
    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    
    // Add marker for tapped location
    addMarker(
      'tap_location',
      position,
      title: 'الموقع المحدد',
      snippet: address ?? 'موقع غير معروف',
    );
  }
  
  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _mapsService.dispose();
    super.dispose();
  }
}