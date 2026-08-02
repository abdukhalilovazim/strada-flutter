import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Web View [BranchesWebViewPage] displaying list of branches.
///
/// Loads the Blade template rendered by Laravel backend.
/// AppBar has NO menu icons, only back button and clean title.
class BranchesWebViewPage extends StatefulWidget {
  const BranchesWebViewPage({super.key});

  @override
  State<BranchesWebViewPage> createState() => _BranchesWebViewPageState();
}

class _BranchesWebViewPageState extends State<BranchesWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isInitialized = false;

  static const String _branchesUrl = 'https://food.khalilovdev.uz/branches-view';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final lang = context.locale.languageCode;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF121217))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              debugPrint('Branches WebView error: ${error.description}');
            },
          ),
        )
        ..loadRequest(
          Uri.parse('$_branchesUrl?lang=$lang'),
          headers: {'Accept-Language': lang},
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('profile.branches'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [], // AppBarda menu yo'q
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
