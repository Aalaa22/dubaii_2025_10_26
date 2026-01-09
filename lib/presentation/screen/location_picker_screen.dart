import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/data/web_services/google_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/google_maps_provider.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:advertising_app/constant/my_color.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  Set<Marker> _markers = {};

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchSuggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  // Offline suggestions management
  bool _hasShownOfflineMessage = false;
  List<Map<String, dynamic>> _currentOfflineSuggestions = [];

  // Google Places API
  final GoogleApiService _googleApiService = GoogleApiService();
  var uuid = const Uuid();
  String _sessionToken = '';

  @override
  void initState() {
    super.initState();
    _sessionToken = uuid.v4();
    // Initialize with provided location or get current location
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _selectedAddress = widget.initialAddress ?? 'Selected Location';
      _updateMarker();
    } else {
      _getCurrentLocationOnInit();
    }
  }

  Future<void> _getCurrentLocationOnInit() async {
    try {
      setState(() {
        _isLoadingAddress = true;
      });

      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();

      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        final position = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        final address = await mapsProvider.getAddressFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );

        setState(() {
          _selectedLocation = position;
          _selectedAddress = address ?? 'Current Location';
          _isLoadingAddress = false;
        });

        _updateMarker();

        // Update offline suggestions based on current location
        _updateOfflineSuggestionsForCurrentLocation(position);
      } else {
        // Try to get a more general location instead of fixed Dubai
        await _setFallbackLocation();
      }
    } catch (e) {
      // Try to get a more general location instead of fixed Dubai
      await _setFallbackLocation();
    }
  }

  Future<void> _setFallbackLocation() async {
    // Try to get approximate location from device settings or use UAE center
    setState(() {
      _selectedLocation = const LatLng(24.4539, 54.3773); // UAE center (Abu Dhabi)
      _selectedAddress = 'United Arab Emirates';
      _isLoadingAddress = false;
    });
    _updateMarker();
  }

  void _updateMarker() {
    if (_selectedLocation != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation!,
            infoWindow: InfoWindow(
              title: 'Selected Location',
              snippet: _selectedAddress ?? 'Unknown location',
            ),
          ),
        };
      });
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _isLoadingAddress = true;
    });

    try {
      final mapsProvider = context.read<GoogleMapsProvider>();
      final address = await mapsProvider.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedAddress = address ?? 'Unknown location';
        _isLoadingAddress = false;
      });

      _updateMarker();

      // Move camera to selected location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16.0),
        );
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Unknown location';
        _isLoadingAddress = false;
      });
      _updateMarker();
    }
  }

  Future<void> _getCurrentLocation() async {
    print('Current location button pressed');

    try {
      setState(() {
        _isLoadingAddress = true;
      });

      // Show loading feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting your current location...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      print('Requesting current location from provider');
      final mapsProvider = context.read<GoogleMapsProvider>();
      await mapsProvider.getCurrentLocation();

      if (mapsProvider.currentLocationData != null) {
        final locationData = mapsProvider.currentLocationData!;
        final position = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        print('Current location found: ${position.latitude}, ${position.longitude}');

        final address = await mapsProvider.getAddressFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );

        print('Address resolved: $address');

        setState(() {
          _selectedLocation = position;
          _selectedAddress = address ?? 'Current Location';
          _isLoadingAddress = false;
        });

        _updateMarker();

        // Move camera to current location with delay and error handling
        Future.delayed(const Duration(milliseconds: 100), () async {
          try {
            if (_mapController != null) {
              print('Moving camera to current location: ${position.latitude}, ${position.longitude}');
              await _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(position, 16.0),
              );
              print('Camera moved to current location successfully');
            } else {
              print('Map controller is null, cannot move camera to current location');
            }
          } catch (e) {
            print('Error moving camera to current location: $e');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location found!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Current location data is null');
        setState(() {
          _isLoadingAddress = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get current location. Please check location permissions and GPS.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Current location error: $e');
      setState(() {
        _isLoadingAddress = false;
      });

      String errorMessage = 'Failed to get current location';
      if (e.toString().contains('permission')) {
        errorMessage = 'Location permission denied. Please enable location access in settings.';
      } else if (e.toString().contains('service')) {
        errorMessage = 'Location service is disabled. Please enable GPS/Location services.';
      } else {
        errorMessage = 'Failed to get current location: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Search for places using Google Places API
  void _searchPlaces(String query) {
    _debounceTimer?.cancel();

    if (query.length < 2) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    try {
      final locale = Localizations.localeOf(context);
      final suggestions = await _googleApiService.searchPlaces(
        query,
        _sessionToken,
        language: locale.languageCode,
      );
      if (mounted) {
        setState(() {
          _searchSuggestions = suggestions;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        _showOfflineSuggestions(query);
      }
    }
  }

  void _updateOfflineSuggestionsForCurrentLocation(LatLng currentLocation) {
    // Update offline suggestions based on current location
    final double lat = currentLocation.latitude;
    final double lng = currentLocation.longitude;

    // Determine which emirate/area the user is in
    List<Map<String, dynamic>> locationBasedSuggestions = [];

    // Dubai area (25.0-25.3 lat, 55.1-55.4 lng)
    if (lat >= 25.0 && lat <= 25.3 && lng >= 55.1 && lng <= 55.4) {
      locationBasedSuggestions = [
        {
          'description': 'Dubai Mall, Dubai, UAE',
          'place_id': 'offline_dubai_mall',
          'structured_formatting': {
            'main_text': 'Dubai Mall',
            'secondary_text': 'Dubai, UAE'
          }
        },
        {
          'description': 'Burj Khalifa, Dubai, UAE',
          'place_id': 'offline_burj_khalifa',
          'structured_formatting': {
            'main_text': 'Burj Khalifa',
            'secondary_text': 'Dubai, UAE'
          }
        },
        {
          'description': 'Dubai Marina, Dubai, UAE',
          'place_id': 'offline_dubai_marina',
          'structured_formatting': {
            'main_text': 'Dubai Marina',
            'secondary_text': 'Dubai, UAE'
          }
        },
      ];
    }
    // Abu Dhabi area (24.2-24.6 lat, 54.2-54.6 lng)
    else if (lat >= 24.2 && lat <= 24.6 && lng >= 54.2 && lng <= 54.6) {
      locationBasedSuggestions = [
        {
          'description': 'Abu Dhabi Mall, Abu Dhabi, UAE',
          'place_id': 'offline_abu_dhabi_mall',
          'structured_formatting': {
            'main_text': 'Abu Dhabi Mall',
            'secondary_text': 'Abu Dhabi, UAE'
          }
        },
        {
          'description': 'Sheikh Zayed Grand Mosque, Abu Dhabi, UAE',
          'place_id': 'offline_grand_mosque',
          'structured_formatting': {
            'main_text': 'Sheikh Zayed Grand Mosque',
            'secondary_text': 'Abu Dhabi, UAE'
          }
        },
        {
          'description': 'Corniche Beach, Abu Dhabi, UAE',
          'place_id': 'offline_corniche',
          'structured_formatting': {
            'main_text': 'Corniche Beach',
            'secondary_text': 'Abu Dhabi, UAE'
          }
        },
      ];
    }
    // Sharjah area (25.3-25.4 lat, 55.3-55.5 lng)
    else if (lat >= 25.3 && lat <= 25.4 && lng >= 55.3 && lng <= 55.5) {
      locationBasedSuggestions = [
        {
          'description': 'Sharjah City Centre, Sharjah, UAE',
          'place_id': 'offline_sharjah_centre',
          'structured_formatting': {
            'main_text': 'Sharjah City Centre',
            'secondary_text': 'Sharjah, UAE'
          }
        },
        {
          'description': 'Al Noor Mosque, Sharjah, UAE',
          'place_id': 'offline_al_noor_mosque',
          'structured_formatting': {
            'main_text': 'Al Noor Mosque',
            'secondary_text': 'Sharjah, UAE'
          }
        },
      ];
    }
    // Default UAE suggestions for other areas
    else {
      locationBasedSuggestions = [
        {
          'description': 'Dubai Mall, Dubai, UAE',
          'place_id': 'offline_dubai_mall',
          'structured_formatting': {
            'main_text': 'Dubai Mall',
            'secondary_text': 'Dubai, UAE'
          }
        },
        {
          'description': 'Abu Dhabi Mall, Abu Dhabi, UAE',
          'place_id': 'offline_abu_dhabi_mall',
          'structured_formatting': {
            'main_text': 'Abu Dhabi Mall',
            'secondary_text': 'Abu Dhabi, UAE'
          }
        },
        {
          'description': 'Sharjah City Centre, Sharjah, UAE',
          'place_id': 'offline_sharjah_centre',
          'structured_formatting': {
            'main_text': 'Sharjah City Centre',
            'secondary_text': 'Sharjah, UAE'
          }
        },
      ];
    }

    _currentOfflineSuggestions = locationBasedSuggestions;
  }

  void _showOfflineSuggestions(String query) {
    // Use current location-based suggestions or fallback to default
    final List<Map<String, dynamic>> offlineSuggestions = _currentOfflineSuggestions.isNotEmpty
        ? _currentOfflineSuggestions
        : [
            {
              'description': 'Dubai Mall, Dubai, UAE',
              'place_id': 'offline_dubai_mall',
              'structured_formatting': {
                'main_text': 'Dubai Mall',
                'secondary_text': 'Dubai, UAE'
              }
            },
            {
              'description': 'Abu Dhabi Mall, Abu Dhabi, UAE',
              'place_id': 'offline_abu_dhabi_mall',
              'structured_formatting': {
                'main_text': 'Abu Dhabi Mall',
                'secondary_text': 'Abu Dhabi, UAE'
              }
            },
          ];

    final filteredSuggestions = offlineSuggestions.where((suggestion) {
      final description = suggestion['description'].toString().toLowerCase();
      final queryLower = query.toLowerCase();
      return description.contains(queryLower);
    }).toList();

    print('Showing offline suggestions: ${filteredSuggestions.length} results');
    setState(() {
      _searchSuggestions = filteredSuggestions;
      _isSearching = false;
      _showSuggestions = true; // Ensure suggestions are shown
    });

    // Show orange message only once per session to improve UX
    if (mounted && !_hasShownOfflineMessage) {
      _hasShownOfflineMessage = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using offline suggestions - API temporarily unavailable'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2), // Shorter duration
        ),
      );
    }
  }

  // Select a place from suggestions
  Future<void> _selectPlace(dynamic prediction) async {
    setState(() {
      _isLoadingAddress = true;
      _showSuggestions = false;
      _searchController.text = prediction['description'] ?? '';
    });

    try {
      final String placeId = prediction['place_id'];

      // Handle offline suggestions
      if (placeId.startsWith('offline_')) {
        _handleOfflineSelection(prediction);
        return;
      }
      final locale = Localizations.localeOf(context);
      final result = await _googleApiService.getPlaceDetails(
        placeId,
        _sessionToken,
        language: locale.languageCode,
      );

      if (result != null) {
        if (result['geometry'] != null && result['geometry']['location'] != null) {
          final location = result['geometry']['location'];
          final double lat = (location['lat'] as num).toDouble();
          final double lng = (location['lng'] as num).toDouble();
          final LatLng position = LatLng(lat, lng);
          final String address = result['formatted_address'] ?? result['name'] ?? prediction['description'] ?? 'Selected Location';

          setState(() {
            _selectedLocation = position;
            _selectedAddress = address;
            _isLoadingAddress = false;
          });

          _updateMarker();
          _moveCameraToPosition(position);
          // Regenerate session token for next search
          setState(() {
            _sessionToken = uuid.v4();
          });
        }
      } else {
        throw Exception('Failed to get place details');
      }
    } catch (e) {
      print('Error selecting place: $e');
      setState(() {
        _isLoadingAddress = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleOfflineSelection(dynamic prediction) {
    // Pre-defined coordinates for offline locations
    const Map<String, LatLng> offlineCoordinates = {
      'offline_dubai_mall': LatLng(25.1972, 55.2795),
      'offline_burj_khalifa': LatLng(25.1972, 55.2744),
      'offline_dubai_marina': LatLng(25.077, 55.139),
      'offline_abu_dhabi_mall': LatLng(24.494, 54.385),
      'offline_grand_mosque': LatLng(24.412, 54.474),
      'offline_corniche': LatLng(24.49, 54.35),
      'offline_sharjah_centre': LatLng(25.33, 55.4),
      'offline_al_noor_mosque': LatLng(25.34, 55.38),
    };

    final placeId = prediction['place_id'];
    final position = offlineCoordinates[placeId];
    final address = prediction['description'] ?? 'Selected Location';

    if (position != null) {
      setState(() {
        _selectedLocation = position;
        _selectedAddress = address;
        _isLoadingAddress = false;
      });
      _updateMarker();
      _moveCameraToPosition(position);
    }
  }

  void _moveCameraToPosition(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.location),
        leading: IconButton(
          icon: Icon(isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? const LatLng(25.2048, 55.2708), // Default to Dubai
              zoom: 12.0,
            ),
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Disable default button
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 10.h,
            left: 15.w,
            right: 15.w,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchPlaces,
                    style: const TextStyle(color: MyColor.KTextColor),
                    decoration: InputDecoration(
                      hintText: "Search for location",
                      hintStyle: TextStyle(color: KTextColor),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _showSuggestions = false;
                                  _searchSuggestions = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
                    ),
                  ),
                ),
                if (_showSuggestions)
                  Container(
                    margin: EdgeInsets.only(top: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: KTextColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: 200.h),
                    child: _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _searchSuggestions[index];
                              return ListTile(
                                title: Text(suggestion['structured_formatting']?['main_text'] ?? suggestion['description'] ?? ''),
                                subtitle: Text(suggestion['structured_formatting']?['secondary_text'] ?? ''),
                                onTap: () {
                                  _selectPlace(suggestion);
                                },
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
          Positioned(
           // top: 50,
            bottom: 300.h,
            right: 20.w,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoadingAddress)
                  const Center(child: CircularProgressIndicator())
                else if (_selectedAddress != null)
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _selectedAddress!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500,color: KTextColor),
                    ),
                  ),
                SizedBox(height: 10.h),
                ElevatedButton(
                  onPressed: (_selectedLocation != null)
                      ? () {
                          context.pop({
                            'location': _selectedLocation,
                            'address': _selectedAddress,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(1, 84, 126, 1),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text("Confirm location",style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}