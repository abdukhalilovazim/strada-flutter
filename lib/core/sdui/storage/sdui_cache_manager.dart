import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sdui_page_model.dart';

/// 💾 SWR Offline Cache & UI Version Synchronization Manager
class SDUICacheManager {
  static final SDUICacheManager _instance = SDUICacheManager._internal();
  factory SDUICacheManager() => _instance;
  SDUICacheManager._internal();

  static const String _keyPrefix = 'sdui_page_cache_';
  static const String _metaPrefix = 'sdui_page_meta_';

  String _buildKey(String screenId, int? branchId) =>
      '$_keyPrefix${screenId}_${branchId ?? 0}';

  String _buildMetaKey(String screenId, int? branchId) =>
      '$_metaPrefix${screenId}_${branchId ?? 0}';

  /// Save SDUI screen JSON locally with timestamp, version UUID, and ETag
  Future<void> savePage(SDUIPageModel page) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(page.screenId, page.branchId);
    final metaKey = _buildMetaKey(page.screenId, page.branchId);

    final jsonStr = jsonEncode(page.toJson());
    await prefs.setString(key, jsonStr);

    final metaData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ttl_seconds': page.cacheTtlSeconds,
      'etag': page.etag,
      'version_uuid': page.versionUuid,
    };
    await prefs.setString(metaKey, jsonEncode(metaData));

    if (kDebugMode) {
      debugPrint('💾 [SDUI Cache] Saved screen "${page.screenId}" with version UUID: ${page.versionUuid}');
    }
  }

  /// Read cached SDUI screen if available
  Future<SDUIPageModel?> getCachedPage(String screenId, {int? branchId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(screenId, branchId);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return SDUIPageModel.fromJson(decoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [SDUI Cache] Error reading cache for "$screenId": $e');
      }
      return null;
    }
  }

  /// Get cached version UUID without decoding the entire page JSON
  Future<String?> getCachedVersionUuid(String screenId, {int? branchId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaKey = _buildMetaKey(screenId, branchId);
      final metaStr = prefs.getString(metaKey);
      if (metaStr != null) {
        final Map<String, dynamic> meta = jsonDecode(metaStr);
        final uuid = meta['version_uuid'] as String?;
        if (uuid != null && uuid.isNotEmpty) return uuid;
      }

      // Fallback: peek inside cached page
      final page = await getCachedPage(screenId, branchId: branchId);
      return page?.versionUuid;
    } catch (_) {
      return null;
    }
  }

  /// Checks if cached UI version matches server version UUID.
  /// Returns true if mismatch (meaning UI has updated or is missing).
  Future<bool> hasVersionMismatch(String screenId, String serverVersionUuid, {int? branchId}) async {
    final cachedUuid = await getCachedVersionUuid(screenId, branchId: branchId);
    if (cachedUuid == null) return true;
    return cachedUuid != serverVersionUuid;
  }

  /// Get cached ETag for HTTP `If-None-Match`
  Future<String?> getCachedETag(String screenId, {int? branchId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaKey = _buildMetaKey(screenId, branchId);
      final metaStr = prefs.getString(metaKey);
      if (metaStr == null) return null;

      final Map<String, dynamic> meta = jsonDecode(metaStr);
      return (meta['version_uuid'] as String?) ?? (meta['etag'] as String?);
    } catch (_) {
      return null;
    }
  }

  /// Clear cached SDUI screen
  Future<void> clearPage(String screenId, {int? branchId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_buildKey(screenId, branchId));
      await prefs.remove(_buildMetaKey(screenId, branchId));
    } catch (_) {}
  }

  /// Check whether the cache has expired based on TTL
  Future<bool> isCacheFresh(String screenId, {int? branchId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaKey = _buildMetaKey(screenId, branchId);
      final metaStr = prefs.getString(metaKey);
      if (metaStr == null) return false;

      final Map<String, dynamic> meta = jsonDecode(metaStr);
      final int timestamp = meta['timestamp'] as int? ?? 0;
      final int ttl = (meta['ttl_seconds'] as int? ?? 300) * 1000;

      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - timestamp) < ttl;
    } catch (_) {
      return false;
    }
  }
}
