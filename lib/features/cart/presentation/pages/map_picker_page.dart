import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  bool _loading = true;
  String _address = '...';
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = latLng;
        _selectedLocation = latLng;
        _loading = false;
      });

      _mapController.move(latLng, 16.0);
      _reverseGeocode(latLng);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = p.street ?? '';
        final name = p.name ?? '';
        final subLocality = p.subLocality ?? '';
        
        String addressLine = '';
        if (street.isNotEmpty) {
          addressLine = street;
        } else if (name.isNotEmpty) {
          addressLine = name;
        } else if (subLocality.isNotEmpty) {
          addressLine = subLocality;
        } else {
          addressLine = "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
        }
        
        setState(() => _address = addressLine);
      }
    } catch (e) {
      if (mounted) setState(() => _address = "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('map.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(41.2995, 69.2401),
                    initialZoom: 16.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                      _reverseGeocode(point);
                    },
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        setState(() => _isMoving = true);
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        setState(() => _isMoving = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'uz.pizzastrada.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_selectedLocation != null)
                          Marker(
                            point: _selectedLocation!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.primary,
                              size: 50,
                            ),
                          ),
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Address info card
                if (!_isMoving && _selectedLocation != null)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _address,
                              maxLines: 2,
                              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // My location button
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (_currentLocation != null) {
                        _mapController.move(_currentLocation!, 16.0);
                        setState(() {
                          _selectedLocation = _currentLocation;
                        });
                        _reverseGeocode(_currentLocation!);
                      }
                    },
                    backgroundColor: Colors.white,
                    mini: true,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),

                // Confirm button
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _selectedLocation == null
                        ? null
                        : () {
                            context.pop({
                              'lat': _selectedLocation!.latitude,
                              'lng': _selectedLocation!.longitude,
                              'address': _address,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('map.confirm'.tr()),
                  ),
                ),
              ],
            ),
    );
  }
}
