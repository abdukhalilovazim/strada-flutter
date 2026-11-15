import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/constants/api_constants.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 📜 Policy & Terms WebView Page
class PolicyWebViewPage extends StatefulWidget {
  final String title;
  final String urlPath;

  const PolicyWebViewPage({
    super.key,
    required this.title,
    required this.urlPath,
  });

  @override
  State<PolicyWebViewPage> createState() => _PolicyWebViewPageState();
}

class _PolicyWebViewPageState extends State<PolicyWebViewPage> {
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

  Future<void> _initController() async {
    final lang = EasyLocalization.of(context)?.locale.languageCode ?? 'ru';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final token = await SecureStorage.getToken();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(isDark ? const Color(0xFF121217) : const Color(0xFFF9FAFB))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage msg) async {
          if (msg.message == 'account_deleted') {
            await _handleAccountDeleted();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              if (uri.queryParameters['status'] == 'deleted') {
                _handleAccountDeleted();
                return NavigationDecision.prevent;
              }
              final scheme = uri.scheme.toLowerCase();
              if (scheme == 'tel' || scheme == 'mailto' || scheme == 'sms') {
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (_) {}
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (url.contains('status=deleted')) {
              _handleAccountDeleted();
            }
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    final cleanPath = widget.urlPath.startsWith('/') ? widget.urlPath.substring(1) : widget.urlPath;
    var urlStr = cleanPath.startsWith('http')
        ? cleanPath
        : '${ApiConstants.webviewBaseUrl}/$cleanPath';

    if (token != null && token.isNotEmpty) {
      final sep = urlStr.contains('?') ? '&' : '?';
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;
      urlStr = '$urlStr${sep}token=$cleanToken';
    }

    controller.loadRequest(
      Uri.parse(urlStr),
      headers: {
        'language': lang,
        'Accept-Language': lang,
        'theme': isDark ? 'dark' : 'light',
        'source': DeviceInfoHelper.appSource,
        'device-id': DeviceInfoHelper.deviceId,
        'device-name': DeviceInfoHelper.deviceName,
        'app-version-code': DeviceInfoHelper.appVersionCode,
        if (token != null)
          'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      },
    );

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  Future<void> _handleAccountDeleted() async {
    await SecureStorage.deleteToken();
    await SecureStorage.deleteUserInfo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.delete_account'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121217) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.neutral900,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
