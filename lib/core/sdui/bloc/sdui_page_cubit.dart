import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import '../models/sdui_page_model.dart';
import '../storage/sdui_cache_manager.dart';
import '../utils/sdui_screen_builder.dart';

abstract class SDUIPageState extends Equatable {
  const SDUIPageState();
  @override
  List<Object?> get props => [];
}

class SDUIPageInitial extends SDUIPageState {}

class SDUIPageLoading extends SDUIPageState {}

class SDUIPageLoaded extends SDUIPageState {
  final SDUIPageModel page;
  final bool isUpdatingUI;

  const SDUIPageLoaded({
    required this.page,
    this.isUpdatingUI = false,
  });

  SDUIPageLoaded copyWith({
    SDUIPageModel? page,
    bool? isUpdatingUI,
  }) {
    return SDUIPageLoaded(
      page: page ?? this.page,
      isUpdatingUI: isUpdatingUI ?? this.isUpdatingUI,
    );
  }

  @override
  List<Object?> get props => [page, isUpdatingUI];
}

class SDUIPageFailure extends SDUIPageState {
  final String message;
  const SDUIPageFailure(this.message);
  @override
  List<Object?> get props => [message];
}

/// 🚀 Universal Server-Driven UI Cubit with SWR & Version UUID Sync
class SDUIPageCubit extends Cubit<SDUIPageState> {
  final String slug;
  final SDUICacheManager _cacheManager = SDUICacheManager();
  final ApiClient _client = getIt<ApiClient>();

  SDUIPageCubit({required this.slug}) : super(SDUIPageInitial());

  Future<void> load({bool forceRefresh = false}) async {
    SDUIPageModel? localPage;

    // 1. SWR 0ms Initial Paint: Load cached or default fallback immediately
    if (!forceRefresh) {
      localPage = await _cacheManager.getCachedPage(slug);
      if (localPage == null) {
        localPage = _getDefaultFallback(slug);
        if (localPage != null) {
          await _cacheManager.savePage(localPage);
        }
      }

      if (localPage != null) {
        emit(SDUIPageLoaded(page: localPage, isUpdatingUI: true));
      } else {
        emit(SDUIPageLoading());
      }
    } else {
      if (state is SDUIPageLoaded) {
        emit((state as SDUIPageLoaded).copyWith(isUpdatingUI: true));
      } else {
        emit(SDUIPageLoading());
      }
    }

    // 2. Version Check: Query lightweight manifest (~150 bytes)
    bool needsFetch = forceRefresh || localPage == null;
    String? serverVersionUuid;

    if (!forceRefresh && localPage != null) {
      try {
        final manifestRes = await _client.get('sdui/manifest');
        final Map<String, dynamic> manifest = manifestRes is Map<String, dynamic>
            ? (manifestRes['data'] is Map<String, dynamic>
                ? manifestRes['data'] as Map<String, dynamic>
                : manifestRes)
            : {};

        final pageData = manifest[slug];
        if (pageData is Map<String, dynamic>) {
          serverVersionUuid = pageData['version_uuid']?.toString();
        } else if (pageData is String) {
          serverVersionUuid = pageData;
        }

        if (serverVersionUuid != null && serverVersionUuid == localPage.versionUuid) {
          // Version match! Zero network overhead.
          needsFetch = false;
        } else {
          needsFetch = true;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [SDUIPageCubit] Manifest check error: $e');
        }
        needsFetch = false;
      }
    }

    if (!needsFetch && localPage != null && state is SDUIPageLoaded) {
      emit((state as SDUIPageLoaded).copyWith(isUpdatingUI: false));
      return;
    }

    // 3. Fetch Full SDUI Page from Backend if Version Changed
    try {
      final response = await _client.get('sdui/pages/$slug');
      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response)
          : {};

      final remotePage = SDUIPageModel.fromJson(data);
      await _cacheManager.savePage(remotePage);

      emit(SDUIPageLoaded(page: remotePage, isUpdatingUI: false));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SDUIPageCubit] Error loading page "$slug": $e');
      }
      if (localPage != null) {
        emit(SDUIPageLoaded(page: localPage, isUpdatingUI: false));
      } else {
        emit(SDUIPageFailure(e.toString()));
      }
    }
  }

  SDUIPageModel? _getDefaultFallback(String slug) {
    return matchSlug(slug);
  }

  static SDUIPageModel? matchSlug(String slug) {
    switch (slug) {
      case 'home':
        return SDUIScreenBuilder.buildHomeScreen(
          sliders: const [],
          categories: const [],
          products: const [],
        );
      case 'cart':
        return SDUIScreenBuilder.buildCartScreen();
      case 'checkout':
        return SDUIScreenBuilder.buildCheckoutScreen();
      case 'profile':
        return SDUIScreenBuilder.buildProfileScreen();
      case 'promotions':
        return SDUIScreenBuilder.buildPromotionsScreen();
      default:
        return null;
    }
  }
}

