import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/storage/shared_prefs.dart';
import '../models/navigation_model.dart';

class SDUINavigationState {
  final List<SDUIBottomNavItem> items;
  final bool isLoading;

  const SDUINavigationState({
    required this.items,
    this.isLoading = false,
  });

  SDUINavigationState copyWith({
    List<SDUIBottomNavItem>? items,
    bool? isLoading,
  }) {
    return SDUINavigationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 🧭 Manages Backend-Driven Dynamic Bottom Navigation Tabs
class SDUINavigationCubit extends Cubit<SDUINavigationState> {
  static const _cacheKey = 'sdui_cached_navigation_v1';
  final ApiClient _client = ApiClient();

  SDUINavigationCubit()
      : super(SDUINavigationState(items: SDUIBottomNavItem.defaultItems())) {
    loadNavigation();
  }

  Future<void> loadNavigation({String locale = 'uz'}) async {
    // 1. SWR: Instant load from local cache if present
    final cachedJson = SharedPrefs.getString(_cacheKey);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(cachedJson) as List<dynamic>;
        final items = list
            .map((e) => SDUIBottomNavItem.fromJson(e as Map<String, dynamic>, locale: locale))
            .toList();
        if (items.isNotEmpty) {
          emit(state.copyWith(items: items));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ [SDUINavigationCubit] Cache decode error: $e');
      }
    }

    // 2. Fetch manifest from Laravel API
    try {
      final response = await _client.get('sdui/manifest');
      final Map<String, dynamic> manifest = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response)
          : {};

      final navData = manifest['navigation'];
      if (navData is List && navData.isNotEmpty) {
        final freshItems = navData
            .map((e) => SDUIBottomNavItem.fromJson(e as Map<String, dynamic>, locale: locale))
            .toList();

        await SharedPrefs.setString(_cacheKey, jsonEncode(navData));
        emit(state.copyWith(items: freshItems));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SDUINavigationCubit] Manifest fetch error: $e');
      }
    }
  }
}

