import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Yandex Maps asosidagi manzil tanlash sahifasi [MapPickerPage].
///
/// Backenddagi `/webview/map-picker` orqali ishlaydi:
/// - Markaziy harakatlanuvchi pin (Yandex Go / Wolt uslubida)
/// - Haqiqiy Yandex Geocoder orqali aniq manzilni aniqlash
/// - Qidiruv (faqat Samarqand hududida qat'iy cheklov bilan)
/// - Yagona boshqaruv paneli (Zoom +, Zoom -, GPS joylashuv)
/// - Filiallarga nisbatan 10 km yetkazib berish radiusini tekshirish
class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final bool useMyLocation;

  const MapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
    this.useMyLocation = false,
  });

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

  List<Map<String, dynamic>> _branches = [];
  bool _isOutOfRange = false;
  double? _nearestDistanceKm;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null && widget.initialLat != 0 && widget.initialLng != 0) {
      _currentLat = widget.initialLat!;
      _currentLng = widget.initialLng!;
    }
    _loadBranches();
    if (widget.useMyLocation || (widget.initialLat == null && widget.initialLng == null)) {
      _checkInitialLocation();
    }
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

  Future<void> _loadBranches() async {
    try {
      final response = await ApiClient().get('branches');
      if (response != null && response['data'] != null) {
        final list = (response['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        if (mounted) {
          setState(() {
            _branches = list;
          });
          _checkDeliveryDistance(_currentLat, _currentLng);
        }
      }
    } catch (_) {
      _checkDeliveryDistance(_currentLat, _currentLng);
    }
  }

  void _checkDeliveryDistance(double lat, double lng) {
    if (_branches.isEmpty) {
      // Samarqand markaziga nisbatan standart 10 km tekshiruv
      final distMeters = Geolocator.distanceBetween(lat, lng, 39.6542, 66.9597);
      final km = distMeters / 1000.0;
      if (mounted) {
        setState(() {
          _nearestDistanceKm = km;
          _isOutOfRange = km > 10.0;
        });
      }
      return;
    }

    double minDistanceMeters = double.infinity;
    for (final b in _branches) {
      final bLat = (b['latitude'] ?? b['lat']) as num?;
      final bLng = (b['longitude'] ?? b['lng']) as num?;
      if (bLat != null && bLng != null && bLat != 0 && bLng != 0) {
        final dist = Geolocator.distanceBetween(lat, lng, bLat.toDouble(), bLng.toDouble());
        if (dist < minDistanceMeters) {
          minDistanceMeters = dist;
        }
      }
    }

    final km = minDistanceMeters.isFinite ? (minDistanceMeters / 1000.0) : 0.0;
    if (mounted) {
      setState(() {
        _nearestDistanceKm = km;
        _isOutOfRange = km > 10.0;
      });
    }
  }

  void _safeRunJavaScript(String script) {
    if (!mounted || _controller == null) return;
    try {
      _controller?.runJavaScript(script).catchError((error) {
        debugPrint('WebView runJavaScript error (handled): $error');
      });
    } catch (e) {
      debugPrint('WebView runJavaScript exception (handled): $e');
    }
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
          _checkDeliveryDistance(pos.latitude, pos.longitude);
          if (!_isMapLoading) {
            _safeRunJavaScript('if (typeof window.moveToCoords === "function") { window.moveToCoords(${pos.latitude}, ${pos.longitude}); }');
          }
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
                final newLat = (data['lat'] as num?)?.toDouble() ?? _currentLat;
                final newLng = (data['lng'] as num?)?.toDouble() ?? _currentLng;
                final inRange = data['in_range'] as bool?;
                setState(() {
                  _currentLat = newLat;
                  _currentLng = newLng;
                  _address = (data['address'] as String?) ?? '';
                  _isGeocoding = false;
                  if (inRange != null) {
                    _isOutOfRange = !inRange;
                  }
                });
                _checkDeliveryDistance(newLat, newLng);
              }
            } else if (type == 'map_ready') {
              if (mounted) {
                setState(() => _isMapLoading = false);
                if (widget.useMyLocation) {
                  _goToMyLocation();
                } else {
                  _safeRunJavaScript('if (typeof window.moveToCoords === "function") { window.moveToCoords($_currentLat, $_currentLng); }');
                }
              }
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
            _safeRunJavaScript('''
              var style = document.createElement('style');
              style.innerHTML = '* { -webkit-user-select: none !important; user-select: none !important; -webkit-touch-callout: none !important; } input, textarea { -webkit-user-select: auto !important; user-select: auto !important; }';
              document.head.appendChild(style);
              document.addEventListener('contextmenu', function(e) { e.preventDefault(); });
            ''');
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

      _safeRunJavaScript('if (typeof window.moveToCoords === "function") { window.moveToCoords(${position.latitude}, ${position.longitude}); }');
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
      _safeRunJavaScript('if (typeof window.searchAddress === "function") { window.searchAddress($escaped); }');
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

          // Top Search Bar (Strada Design System standartida)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _onSearch(),
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.neutral900,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'map.search_hint'.tr(),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral400,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.neutral500),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
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

          // Bottom Controls & Address Card (Bitta ustun - bir-birini hech qachon to'sib qo'ymaydi)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Yagona xarita boshqaruv bloki (Zoom +, Zoom -, Joylashuvim)
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: _buildMapControls(isDark),
                ),

                // Manzil va tasdiqlash kartochkasi
                _buildBottomAddressCard(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Yagona xarita boshqaruv tugmalari (Zoom In, Zoom Out, Joylashuv)
  Widget _buildMapControls(bool isDark) {
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.neutral800 : AppColors.neutral200;
    final dividerColor = isDark ? AppColors.neutral800 : AppColors.neutral200.withValues(alpha: 0.6);
    final iconColor = isDark ? Colors.white : AppColors.neutral800;

    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom In (+)
          InkWell(
            onTap: () => _safeRunJavaScript('if (typeof window.zoomIn === "function") { window.zoomIn(); }'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              width: 44,
              height: 42,
              child: Icon(Icons.add_rounded, color: iconColor, size: 22),
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),

          // Zoom Out (-)
          InkWell(
            onTap: () => _safeRunJavaScript('if (typeof window.zoomOut === "function") { window.zoomOut(); }'),
            child: SizedBox(
              width: 44,
              height: 42,
              child: Icon(Icons.remove_rounded, color: iconColor, size: 22),
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),

          // Mening joylashuvim (GPS)
          InkWell(
            onTap: _goToMyLocation,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: SizedBox(
              width: 44,
              height: 42,
              child: Center(
                child: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Manzil ko'rsatish va tasdiqlash kartochkasi
  Widget _buildBottomAddressCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200.withValues(alpha: 0.5),
          width: 1,
        ),
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
                    color: (_isOutOfRange ? AppColors.error : AppColors.primary).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isOutOfRange ? Icons.location_off_rounded : Icons.location_on_rounded,
                    color: _isOutOfRange ? AppColors.error : AppColors.primary,
                    size: 22,
                  ),
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
                            ? 'map.determining_address'.tr()
                            : (_address.isNotEmpty ? _address : 'map.no_address_selected'.tr()),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                      ),
                      // 10 km yetkazib berish zonasi statusi
                      if (!_isGeocoding && _address.isNotEmpty && _nearestDistanceKm != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                _isOutOfRange ? Icons.cancel_rounded : Icons.check_circle_rounded,
                                size: 14,
                                color: _isOutOfRange ? AppColors.error : AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isOutOfRange
                                    ? '${'map.out_of_delivery_range'.tr()} (${_nearestDistanceKm!.toStringAsFixed(1)} km)'
                                    : '${'map.in_delivery_range'.tr()} (${_nearestDistanceKm!.toStringAsFixed(1)} km)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _isOutOfRange ? AppColors.error : AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                onPressed: (_isGeocoding || _address.isEmpty || _isOutOfRange)
                    ? null
                    : () {
                        context.pop({
                          'lat': _currentLat,
                          'lng': _currentLng,
                          'address': _address,
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOutOfRange ? AppColors.neutral400 : AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? AppColors.neutral800 : AppColors.neutral300,
                  disabledForegroundColor: AppColors.neutral500,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isGeocoding
                      ? 'map.determining_address'.tr()
                      : (_isOutOfRange
                          ? 'map.out_of_range_btn'.tr()
                          : (_address.isEmpty
                              ? 'map.no_address_selected'.tr()
                              : 'map.confirm'.tr())),
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
