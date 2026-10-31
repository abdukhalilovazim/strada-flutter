import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sdui_action_model.dart';

typedef SDUIActionHandler = void Function(SDUIAction action);

/// 🚀 Declarative Action Dispatcher (Safe & Sandbox Compliant)
class SDUIActionDispatcher {
  static Future<void> dispatch(
    BuildContext context,
    SDUIAction action, {
    void Function(String categorySlug)? onFilterCategory,
  }) async {
    switch (action.type) {
      case 'navigate':
        final route = action.target;
        if (route != null && route.isNotEmpty) {
          context.push(route, extra: action.payload);
        }
        break;

      case 'open_url':
        final url = action.target;
        if (url != null && url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;

      case 'call_phone':
        final phone = action.target ?? action.payload['phone']?.toString();
        if (phone != null && phone.isNotEmpty) {
          final uri = Uri.parse('tel:$phone');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
        break;

      case 'filter_category':
        final categorySlug = action.target ?? action.payload['slug']?.toString();
        if (categorySlug != null && onFilterCategory != null) {
          onFilterCategory(categorySlug);
        }
        break;

      case 'open_sheet':
        // Pre-compiled sheets (e.g. variant picker or address picker)
        final sheetTarget = action.target;
        if (sheetTarget == 'cart') {
          context.push('/cart');
        }
        break;

      case 'none':
      default:
        // No-op for unregistered or benign actions
        break;
    }
  }
}

