import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late YandexMapController _controller;
  Point _targetPoint = const Point(latitude: 39.6465, longitude: 66.9535); // Samarqand, Amir Temur
  String _address = '...';
  bool _isMoving = false;
  bool _isLoadingLocation = false;

  Future<void> _reverseGeocode(Point point) async {
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      final point = Point(latitude: position.latitude, longitude: position.longitude);
      _controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: 15),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manzilni tanlang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) {
              _controller = controller;
              _controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _targetPoint, zoom: 15),
                ),
              );
              _reverseGeocode(_targetPoint);
            },
            onCameraPositionChanged: (pos, reason, finished) {
              setState(() {
                _targetPoint = pos.target;
                _isMoving = !finished;
              });
              if (finished) {
                _reverseGeocode(pos.target);
              }
            },
          ),
          if (!_isMoving)
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
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4)),
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
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_on_rounded,
                color: _isMoving ? AppColors.primary.withOpacity(0.7) : AppColors.primary,
                size: 48,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 120,
            child: FloatingActionButton(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              mini: true,
              child: _isLoadingLocation 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, color: AppColors.primary),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: ElevatedButton(
              onPressed: _isMoving ? null : () => context.pop({
                'point': _targetPoint,
                'address': _address,
              }),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Manzilni tasdiqlash'),
            ),
          ),
        ],
      ),
    );
  }
}
