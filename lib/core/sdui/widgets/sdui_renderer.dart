import 'package:flutter/material.dart';
import '../models/sdui_action_model.dart';
import '../models/sdui_page_model.dart';
import '../registry/sdui_action_dispatcher.dart';
import '../registry/sdui_component_registry.dart';

/// ⚡ High-Performance Declarative SDUI Renderer
/// Virtualizes declarative JSON layout sections into Flutter Slivers.
class SDUIRenderer extends StatelessWidget {
  final SDUIPageModel page;
  final String? selectedCategorySlug;
  final Future<void> Function()? onRefresh;
  final void Function(SDUIAction action)? onAction;
  final void Function(String categorySlug)? onFilterCategory;
  final List<Widget>? leadingSlivers;

  const SDUIRenderer({
    super.key,
    required this.page,
    this.selectedCategorySlug,
    this.onRefresh,
    this.onAction,
    this.onFilterCategory,
    this.leadingSlivers,
  });

  void _handleAction(BuildContext context, SDUIAction action) {
    if (action.type == 'filter_category') {
      final slug = action.target ?? action.payload['slug']?.toString();
      if (slug != null && onFilterCategory != null) {
        onFilterCategory!(slug);
        return;
      }
    }

    if (onAction != null) {
      onAction!(action);
    } else {
      SDUIActionDispatcher.dispatch(
        context,
        action,
        onFilterCategory: onFilterCategory,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registry = SDUIComponentRegistry();

    final slivers = <Widget>[
      if (leadingSlivers != null) ...leadingSlivers!,
      ...page.sections.map((section) {
        return registry.buildSliver(
          context,
          section,
          (action) => _handleAction(context, action),
          selectedCategorySlug,
        );
      }),
    ];

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: slivers,
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: slivers,
    );
  }
}
