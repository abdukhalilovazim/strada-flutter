import 'package:equatable/equatable.dart';
import 'sdui_section_model.dart';

/// 📄 Declarative SDUI Screen / Page Model
class SDUIPageModel extends Equatable {
  final String version;
  final String versionUuid;
  final String screenId;
  final Map<String, dynamic> meta;
  final List<SDUISectionModel> sections;

  const SDUIPageModel({
    required this.version,
    required this.versionUuid,
    required this.screenId,
    this.meta = const {},
    this.sections = const [],
  });

  /// Cache TTL in seconds (defaults to 300s = 5 mins)
  int get cacheTtlSeconds => (meta['cache_ttl_seconds'] as num?)?.toInt() ?? 300;

  /// HTTP ETag or content hash for SWR revalidation
  String? get etag => meta['etag'] as String?;

  /// Resolved Branch ID for location-aware menus
  int? get branchId => (meta['branch_id'] as num?)?.toInt();

  /// Branch Title (e.g., "Strada Yunusobod")
  String? get branchTitle => meta['branch_title'] as String?;

  /// Screen title
  String get title => (meta['title'] as String?) ?? 'Pizza Strada';

  SDUIPageModel copyWith({
    String? version,
    String? versionUuid,
    String? screenId,
    Map<String, dynamic>? meta,
    List<SDUISectionModel>? sections,
  }) {
    return SDUIPageModel(
      version: version ?? this.version,
      versionUuid: versionUuid ?? this.versionUuid,
      screenId: screenId ?? this.screenId,
      meta: meta ?? this.meta,
      sections: sections ?? this.sections,
    );
  }

  factory SDUIPageModel.fromJson(Map<String, dynamic> json) {
    final metaData = (json['meta'] as Map<String, dynamic>?) ?? {};
    if (json['title'] != null && !metaData.containsKey('title')) {
      metaData['title'] = json['title'];
    }

    final String versionUuid = json['version_uuid']?.toString() ??
        metaData['version_uuid']?.toString() ??
        json['etag']?.toString() ??
        'default_v1';

    return SDUIPageModel(
      version: json['version']?.toString() ?? '1.0.0',
      versionUuid: versionUuid,
      screenId: json['screen_id']?.toString() ?? json['id']?.toString() ?? 'default',
      meta: metaData,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => SDUISectionModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'version_uuid': versionUuid,
    'screen_id': screenId,
    'meta': meta,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [version, versionUuid, screenId, meta, sections];
}
