import 'package:equatable/equatable.dart';
import 'sdui_section_model.dart';

/// 📄 Declarative SDUI Screen / Page Model
class SDUIPageModel extends Equatable {
  final String version;
  final String screenId;
  final Map<String, dynamic> meta;
  final List<SDUISectionModel> sections;

  const SDUIPageModel({
    required this.version,
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

  factory SDUIPageModel.fromJson(Map<String, dynamic> json) {
    return SDUIPageModel(
      version: json['version']?.toString() ?? '1.0.0',
      screenId: json['screen_id']?.toString() ?? 'default',
      meta: (json['meta'] as Map<String, dynamic>?) ?? {},
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => SDUISectionModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'screen_id': screenId,
    'meta': meta,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [version, screenId, meta, sections];
}

