import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Yandex Maps asosidagi manzil tanlash sahifasi [MapPickerPage].
///
/// WebView orqali Yandex Maps JS API 2.1 integratsiyasi:
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

  static const String _yandexApiKey = '5a208825-198a-478f-bad4-2c686c374f08';

  @override
  void initState() {
    super.initState();
    _initController();
    _checkInitialLocation();
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
    final lang = _getLanguageCode();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF3F4F6))
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
      )
      ..loadHtmlString(_buildHtml(lang), baseUrl: 'https://pizzastrada.uz');

    _controller = controller;
  }

  String _getLanguageCode() {
    final code = EasyLocalization.of(context)?.locale.languageCode ?? 'uz';
    if (code == 'ru') return 'ru_RU';
    if (code == 'en') return 'en_US';
    return 'uz_UZ';
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

  String _buildHtml(String lang) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body, #map { width: 100%; height: 100%; overflow: hidden; background: #e5e7eb; }
        
        #pin-container {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -100%);
            z-index: 1000;
            pointer-events: none;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .pin-svg {
            width: 44px;
            height: 44px;
            filter: drop-shadow(0 4px 8px rgba(0,0,0,0.25));
            transition: transform 0.18s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        .pin-shadow {
            width: 14px;
            height: 6px;
            background: rgba(0, 0, 0, 0.28);
            border-radius: 50%;
            margin-top: -3px;
            transition: transform 0.18s, opacity 0.18s;
        }
        .moving .pin-svg {
            transform: translateY(-14px) scale(1.08);
        }
        .moving .pin-shadow {
            transform: scale(0.5);
            opacity: 0.2;
        }
        .ymaps-2-1-79-copyright { display: none !important; }
    </style>
    <script src="https://api-maps.yandex.ru/2.1/?apikey=$_yandexApiKey&lang=$lang" type="text/javascript"></script>
</head>
<body>
    <div id="map"></div>
    <div id="pin-container">
        <svg class="pin-svg" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2ZM12 11.5C10.62 11.5 9.5 10.38 9.5 9C9.5 7.62 10.62 6.5 12 6.5C13.38 6.5 14.5 7.62 14.5 9C14.5 10.38 13.38 11.5 12 11.5Z" fill="#D32F2F"/>
        </svg>
        <div class="pin-shadow"></div>
    </div>

    <script>
        let myMap = null;
        let pinContainer = document.getElementById('pin-container');
        let geocodeTimeout = null;

        function sendToFlutter(data) {
            if (window.FlutterMap) {
                window.FlutterMap.postMessage(JSON.stringify(data));
            }
        }

        ymaps.ready(function() {
            myMap = new ymaps.Map('map', {
                center: [$_currentLat, $_currentLng],
                zoom: 16,
                controls: []
            }, {
                suppressMapOpenBlock: true
            });

            myMap.behaviors.enable(['drag', 'scrollZoom', 'multiTouch']);

            myMap.events.add('actionbegin', function() {
                pinContainer.classList.add('moving');
                sendToFlutter({ type: 'moving' });
            });

            myMap.events.add('actionend', function() {
                pinContainer.classList.remove('moving');
                triggerGeocode();
            });

            sendToFlutter({ type: 'map_ready' });
            triggerGeocode();
        });

        function triggerGeocode() {
            if (!myMap) return;
            const center = myMap.getCenter();
            clearTimeout(geocodeTimeout);
            geocodeTimeout = setTimeout(function() {
                ymaps.geocode(center, { results: 1 }).then(function(res) {
                    const geo = res.geoObjects.get(0);
                    let address = '';
                    if (geo) {
                        address = geo.getAddressLine();
                    } else {
                        address = center[0].toFixed(5) + ', ' + center[1].toFixed(5);
                    }
                    sendToFlutter({
                        type: 'location_changed',
                        lat: center[0],
                        lng: center[1],
                        address: address
                    });
                }).catch(function() {
                    sendToFlutter({
                        type: 'location_changed',
                        lat: center[0],
                        lng: center[1],
                        address: center[0].toFixed(5) + ', ' + center[1].toFixed(5)
                    });
                });
            }, 250);
        }

        window.moveToCoords = function(lat, lng) {
            if (myMap) {
                myMap.setCenter([lat, lng], 16, { checkZoomRange: true, duration: 400 });
            }
        };

        window.searchAddress = function(query) {
            if (!query || !myMap) return;
            ymaps.geocode(query, { results: 1 }).then(function(res) {
                const geo = res.geoObjects.get(0);
                if (geo) {
                    const coords = geo.geometry.getCoordinates();
                    myMap.setCenter(coords, 16, { duration: 400 });
                } else {
                    sendToFlutter({ type: 'search_not_found' });
                }
            }).catch(function() {
                sendToFlutter({ type: 'search_not_found' });
            });
        };
    </script>
</body>
</html>
''';
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
