import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import '../models/page_model.dart';
import '../storage/cache_manager.dart';
import '../utils/screen_builder.dart';

abstract class SDUIPageState extends Equatable {
  const SDUIPageState();
  @override
  List<Object?> get props => [];
}

class SDUIPageInitial extends SDUIPageState {}

class SDUIPageLoading extends SDUIPageState {}

class SDUIPageUpdating extends SDUIPageState {
  final bool isSuccess;
  final String title;
  final String? subtitle;

  const SDUIPageUpdating({
    this.isSuccess = false,
    this.title = 'UI yangilanmoqda...',
    this.subtitle,
  });

  @override
  List<Object?> get props => [isSuccess, title, subtitle];
}

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
    final localPage = await _cacheManager.getCachedPage(slug);
    final localVersionUuid = localPage?.versionUuid;

    // ⚡ 1. Version Check: Query lightweight manifest (~150 bytes) FIRST
    String? serverVersionUuid;
    bool hasManifestError = false;

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
    } catch (e) {
      hasManifestError = true;
      if (kDebugMode) {
        debugPrint('⚠️ [SDUIPageCubit] Manifest check error: $e');
      }
    }

    // ⚡ 2. Check if versions match:
    final isVersionMatch = !forceRefresh &&
        localPage != null &&
        (serverVersionUuid != null && serverVersionUuid == localVersionUuid);

    if (isVersionMatch || (hasManifestError && localPage != null)) {
      // 🚀 ZERO-TRAFFIC CACHE HIT!
      if (kDebugMode) {
        debugPrint('⚡ [SDUIPageCubit] "$slug" versions match ($localVersionUuid). Skipping API! Instant load.');
      }
      emit(SDUIPageLoaded(page: localPage, isUpdatingUI: false));
      return;
    }

    // ⚡ 3. Version MISMATCH or cache empty:
    // Full screen loader: "UI yangilanmoqda..." -> success icon -> open UI
    if (kDebugMode) {
      debugPrint('🔄 [SDUIPageCubit] "$slug" version mismatch (local: $localVersionUuid, server: $serverVersionUuid). Updating UI.');
    }

    emit(const SDUIPageUpdating(isSuccess: false));

    try {
      final response = await _client.get('sdui/pages/$slug');
      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response)
          : {};

      final remotePage = SDUIPageModel.fromJson(data);
      await _cacheManager.savePage(remotePage);

      // Show success checkmark: "UI yangilandi!"
      emit(const SDUIPageUpdating(isSuccess: true));

      // Wait brief moment for user to see success state
      await Future.delayed(const Duration(milliseconds: 700));

      emit(SDUIPageLoaded(page: remotePage, isUpdatingUI: false));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SDUIPageCubit] Error loading page "$slug": $e');
      }
      if (localPage != null) {
        emit(SDUIPageLoaded(page: localPage, isUpdatingUI: false));
      } else {
        final fallback = _getDefaultFallback(slug);
        if (fallback != null) {
          emit(SDUIPageLoaded(page: fallback, isUpdatingUI: false));
        } else {
          emit(SDUIPageFailure(e.toString()));
        }
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

