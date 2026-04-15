import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late YandexMapController _controller;
  Point _targetPoint = const Point(latitude: 41.311081, longitude: 69.240562); // Tashkent center
  bool _isMoving = false;

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
            },
            onCameraPositionChanged: (pos, reason, finished) {
              setState(() {
                _targetPoint = pos.target;
                _isMoving = !finished;
              });
            },
          ),
          // Center marker
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
          // Bottom button
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: ElevatedButton(
              onPressed: _isMoving ? null : () => context.pop(_targetPoint),
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
