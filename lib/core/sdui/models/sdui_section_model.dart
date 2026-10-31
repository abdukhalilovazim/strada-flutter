import 'package:equatable/equatable.dart';
import 'sdui_action_model.dart';
import 'sdui_component_model.dart';

/// 🧱 Declarative SDUI Layout Section
class SDUISectionModel extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> properties;
  final List<SDUIComponentModel> items;
  final SDUIAction? action;

  const SDUISectionModel({
    required this.id,
    required this.type,
    this.properties = const {},
    this.items = const [],
    this.action,
  });

  /// Compatibility getter for section properties
  Map<String, dynamic> get propsMap => properties;

  factory SDUISectionModel.fromJson(Map<String, dynamic> json) {
    return SDUISectionModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'unknown',
      properties: (json['properties'] as Map<String, dynamic>?) ??
          (json['props'] as Map<String, dynamic>?) ??
          {},
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => SDUIComponentModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      action: json['action'] != null
          ? SDUIAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'props': properties,
    'items': items.map((i) => i.toJson()).toList(),
    if (action != null) 'action': action!.toJson(),
  };

  @override
  List<Object?> get props => [id, type, properties, items, action];
}
