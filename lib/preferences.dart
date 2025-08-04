import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesModel {
  PreferencesModel({
    required this.preferences,
  });

  final Map<String, String?> preferences;

  PreferencesModel copyWith({
    Map<String, String?>? preferences,
  }) {
    return PreferencesModel(
      preferences: preferences ?? this.preferences,
    );
  }
}

class PreferencesNotifier extends ValueNotifier<PreferencesModel> {
  // Add a Completer to track when preferences are loaded
  final Completer<void> _loadCompleter = Completer<void>();

  Future<void> get loadPreferencesCompleted => _loadCompleter.future;

  PreferencesNotifier() : super(PreferencesModel(preferences: {})) {
    _loadPreferences();
  }

  Future<void> setPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    this.value = this
        .value
        .copyWith(preferences: {...this.value.preferences, key: value});
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final preferences = <String, String?>{};
      for (var key in keys) {
        preferences[key] = prefs.getString(key);
      }
      value = value.copyWith(preferences: preferences);

      // Complete the future when preferences are loaded
      if (!_loadCompleter.isCompleted) {
        _loadCompleter.complete();
      }
    } catch (e) {
      // Complete with error if loading fails
      if (!_loadCompleter.isCompleted) {
        _loadCompleter.completeError(e);
      }
    }
  }
}
