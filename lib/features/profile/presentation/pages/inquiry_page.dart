import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Web View [InquiryPage] for submitting inquiries.
///
/// Loads the Blade template rendered by Laravel backend with app's active locale.
/// AppBar has NO menu icons, only back button and clean title.
class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isInitialized = false;

  static const String _inquiryUrl = 'https://food.khalilovdev.uz/inquiry';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initWebView();
    }
  }

  Future<void> _initWebView() async {
    final lang = context.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = isDark ? 'dark' : 'light';
    final bgColor = isDark ? const Color(0xFF121217) : const Color(0xFFF9FAFB);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(bgColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            _controller.runJavaScript('''
              (function() {
                var css = '* { -webkit-touch-callout: none !important; -webkit-user-select: none !important; user-select: none !important; } input, textarea { -webkit-user-select: auto !important; user-select: auto !important; }';
                var style = document.createElement('style');
                style.type = 'text/css';
                style.appendChild(document.createTextNode(css));
                document.head.appendChild(style);
              })();
            ''');
          },
          onWebResourceError: (error) {
            debugPrint('Inquiry WebView error: ${error.description}');
          },
        ),
      );

    final phone = await SecureStorage.getUserPhone() ?? '';
    final name = await SecureStorage.getUserName() ?? '';

    final uri = Uri.parse(_inquiryUrl).replace(queryParameters: {
      'lang': lang,
      'theme': themeMode,
      if (phone.isNotEmpty) 'phone': phone,
      if (name.isNotEmpty) 'name': name,
    });

    await _controller.loadRequest(
      uri,
      headers: {
        'Accept-Language': lang,
        'X-App-Theme': themeMode,
        if (phone.isNotEmpty) 'X-User-Phone': phone,
        if (name.isNotEmpty) 'X-User-Name': name,
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('profile.support_inquiry'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [], // AppBarda hech qanday menu chiqmaydi
      ),
      body: Stack(
        children: [
          if (_isInitialized) WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
