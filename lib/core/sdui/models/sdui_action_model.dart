import 'package:equatable/equatable.dart';

/// 🛡 Declarative SDUI Action Contract (Apple Guideline 2.5.2 & Google Play Compliant)
/// Strictly declarative actions with NO dynamic eval, JS runtime, or arbitrary code execution.
class SDUIAction extends Equatable {
  final String type; // 'navigate', 'open_sheet', 'add_to_cart', 'open_url', 'call_phone', 'filter_category'
  final String? target; // route path, URL, sheet identifier, or category slug
  final Map<String, dynamic> payload;

  const SDUIAction({
    required this.type,
    this.target,
    this.payload = const {},
  });

  factory SDUIAction.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SDUIAction(type: 'none');
    return SDUIAction(
      type: json['type'] as String? ?? 'none',
      target: json['target'] as String? ?? json['route'] as String? ?? json['url'] as String?,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (target != null) 'target': target,
    'payload': payload,
  };

  @override
  List<Object?> get props => [type, target, payload];
}
