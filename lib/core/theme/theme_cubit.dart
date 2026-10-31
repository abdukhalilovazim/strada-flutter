import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/storage/shared_prefs.dart';

/// Global cubit that manages the app's [ThemeMode].
///
/// Persists the selected theme via [SharedPrefs].
/// Default mode: [ThemeMode.light].
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light) {
    _loadSaved();
  }

  /// Loads the previously saved theme from [SharedPrefs].
  void _loadSaved() {
    final saved = SharedPrefs.getThemeMode();
    emit(saved);
  }

  /// Toggles between [ThemeMode.light] and [ThemeMode.dark].
  Future<void> toggle() async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await SharedPrefs.saveThemeMode(next);
    emit(next);
  }

  /// Sets a specific [ThemeMode] and persists it.
  Future<void> setMode(ThemeMode mode) async {
    await SharedPrefs.saveThemeMode(mode);
    emit(mode);
  }
}
