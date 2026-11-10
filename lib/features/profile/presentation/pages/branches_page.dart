import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 🏢 Backend Blade-Managed Branches Page (WebView)
class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initController();
    }
  }

  void _initController() {
    final lang = EasyLocalization.of(context)?.locale.languageCode ?? 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(isDark ? const Color(0xFF121217) : const Color(0xFFF9FAFB))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              final scheme = uri.scheme.toLowerCase();
              if (scheme == 'tel' ||
                  scheme == 'mailto' ||
                  scheme == 'sms' ||
                  request.url.contains('maps') ||
                  request.url.contains('yandex')) {
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Launch URL error: $e');
                }
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('Branches WebView error: ${error.description}');
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    final uri = Uri.parse('${ApiConstants.webviewBaseUrl}/branches');
    final headers = {
      'app-version-code': DeviceInfoHelper.appVersionCode,
      'device-id': DeviceInfoHelper.deviceId,
      'device-name': DeviceInfoHelper.deviceName,
      'language': lang,
      'Accept-Language': lang,
      'theme': isDark ? 'dark' : 'light',
      'source': DeviceInfoHelper.appSource,
    };

    controller.loadRequest(uri, headers: headers);
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121217) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'profile.branches'.tr(),
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF121217) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
