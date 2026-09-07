import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Yandex Maps asosidagi manzil tanlash sahifasi [MapPickerPage].
///
/// Backenddagi `/webview/map-picker` orqali ishlaydi:
/// - Markaziy harakatlanuvchi pin (Yandex Go / Wolt uslubida)
/// - Haqiqiy Yandex Geocoder orqali aniq manzilni aniqlash
/// - Qidiruv (ko'cha yoki joy nomi bo'yicha)
/// - "Mening joylashuvim" (GPS) tugmasi
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  WebViewController? _controller;
  final TextEditingController _searchController = TextEditingController();

  double _currentLat = 39.6542; // Samarqand default
  double _currentLng = 66.9597;
  String _address = '';
  bool _isGeocoding = true;
  bool _isMapLoading = true;
  bool _isLocating = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initController();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        if (mounted) {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
          _controller?.runJavaScript('window.moveToCoords(${pos.latitude}, ${pos.longitude});');
        }
      }
    } catch (_) {}
  }

  void _initController() {
    final lang = EasyLocalization.of(context)?.locale.languageCode ?? 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = isDark ? 'dark' : 'light';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(isDark ? const Color(0xFF121217) : const Color(0xFFF3F4F6))
      ..addJavaScriptChannel(
        'FlutterMap',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            final type = data['type'] as String?;

            if (type == 'moving') {
              if (mounted) setState(() => _isGeocoding = true);
            } else if (type == 'location_changed') {
              if (mounted) {
                setState(() {
                  _currentLat = (data['lat'] as num?)?.toDouble() ?? _currentLat;
                  _currentLng = (data['lng'] as num?)?.toDouble() ?? _currentLng;
                  _address = (data['address'] as String?) ?? '';
                  _isGeocoding = false;
                });
              }
            } else if (type == 'map_ready') {
              if (mounted) setState(() => _isMapLoading = false);
            } else if (type == 'search_not_found') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('error.not_found'.tr()),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Map message parse error: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isMapLoading = false);
          },
        ),
      );

    final queryParams = {
      'lat': _currentLat.toString(),
      'lng': _currentLng.toString(),
      'lang': lang,
      'theme': themeMode,
      'app_version_code': DeviceInfoHelper.appVersionCode,
      'device_id': DeviceInfoHelper.deviceId,
      'device_name': DeviceInfoHelper.deviceName,
      'source': DeviceInfoHelper.appSource,
    };

    final uri = Uri.parse('${ApiConstants.webviewBaseUrl}/map-picker')
        .replace(queryParameters: queryParams);

    final headers = {
      'app-version-code': DeviceInfoHelper.appVersionCode,
      'device-id': DeviceInfoHelper.deviceId,
      'device-name': DeviceInfoHelper.deviceName,
      'language': lang,
      'theme': themeMode,
      'source': DeviceInfoHelper.appSource,
    };

    controller.loadRequest(uri, headers: headers);
    _controller = controller;
  }

  Future<void> _goToMyLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('error.location_permission_denied'.tr())),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _controller?.runJavaScript('window.moveToCoords(${position.latitude}, ${position.longitude});');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error.location_service_disabled'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      FocusScope.of(context).unfocus();
      final escaped = jsonEncode(query);
      _controller?.runJavaScript('window.searchAddress($escaped);');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('map.title'.tr()),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Yandex Maps WebView
          if (_controller != null) WebViewWidget(controller: _controller!),

          // Top Search Bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _onSearch(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'map.search_hint'.tr(),
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                    onPressed: _onSearch,
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isMapLoading)
            Container(
              color: isDark ? AppColors.darkBackground : Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // My Location Button
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              elevation: 4,
              mini: true,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.my_location_rounded, color: AppColors.primary),
            ),
          ),

          // Bottom Address Card & Confirm Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'checkout.address'.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isGeocoding
                                    ? '...'
                                    : (_address.isNotEmpty ? _address : 'checkout.select_address'.tr()),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.neutral900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isGeocoding || _address.isEmpty)
                            ? null
                            : () {
                                context.pop({
                                  'lat': _currentLat,
                                  'lng': _currentLng,
                                  'address': _address,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.neutral400,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'map.confirm'.tr(),
                          style: AppTextStyles.labelLarge.copyWith(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
