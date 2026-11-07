import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

extension LocalizationExtension on String {
  /// Translates the key using EasyLocalization [tr()].
  /// If the key is not found (i.e. [tr()] returns the key itself),
  /// it gracefully returns [fallback] instead of showing raw technical keys like 'notifications.title'.
  String trOr(
    String fallback, {
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
    String? gender,
  }) {
    final translated = tr(
      this,
      context: context,
      args: args,
      namedArgs: namedArgs,
      gender: gender,
    );
    if (translated == this) {
      return fallback;
    }
    return translated;
  }
}