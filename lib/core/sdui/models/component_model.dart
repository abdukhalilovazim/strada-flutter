import 'package:equatable/equatable.dart';
import 'action_model.dart';

/// 🧩 Declarative SDUI Component Element
class SDUIComponentModel extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> properties;
  final SDUIAction? action;

  const SDUIComponentModel({
    required this.id,
    required this.type,
    this.properties = const {},
    this.action,
  });

  /// Compatibility getter for component properties
  Map<String, dynamic> get propsMap => properties;

  factory SDUIComponentModel.fromJson(Map<String, dynamic> json) {
    return SDUIComponentModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'unknown',
      properties: (json['properties'] as Map<String, dynamic>?) ??
          (json['props'] as Map<String, dynamic>?) ??
          {},
      action: json['action'] != null
          ? SDUIAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'props': properties,
    if (action != null) 'action': action!.toJson(),
  };

  @override
  List<Object?> get props => [id, type, properties, action];
}
