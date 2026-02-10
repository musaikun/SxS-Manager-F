import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/time_preset.dart';

/// 時間設定プリセットの状態管理
class TimePresetNotifier extends StateNotifier<List<TimePreset>> {
  TimePresetNotifier() : super(_defaultPresets) {
    _loadFromStorage();
  }

  static const String _storageKey = 'time_presets';

  // デフォルトのプリセット
  static final List<TimePreset> _defaultPresets = [
    TimePreset(
      label: '9:00-18:00',
      startHour: 9,
      startMinute: 0,
      endHour: 18,
      endMinute: 0,
    ),
    TimePreset(
      label: '10:00-19:00',
      startHour: 10,
      startMinute: 0,
      endHour: 19,
      endMinute: 0,
    ),
    TimePreset(
      label: '13:00-22:00',
      startHour: 13,
      startMinute: 0,
      endHour: 22,
      endMinute: 0,
    ),
    TimePreset(
      label: '17:00-23:00',
      startHour: 17,
      startMinute: 0,
      endHour: 23,
      endMinute: 0,
    ),
    TimePreset(
      label: '22:00-翌7:00',
      startHour: 22,
      startMinute: 0,
      endHour: 7,
      endMinute: 0,
      isNextDay: true,
    ),
  ];

  // ==================== データ永続化 ====================

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final List<TimePreset> presets = jsonList
            .map((json) => TimePreset.fromJson(json as Map<String, dynamic>))
            .toList();
        state = presets;
      }
    } catch (e) {
      // デバッグ: Failed to load time presets: $e
      // エラー時はデフォルトプリセットを使用
      state = _defaultPresets;
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((preset) => preset.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      // デバッグ: Failed to save time presets: $e
    }
  }

  // ==================== プリセット操作 ====================

  /// プリセットを追加（最大5個まで）
  void addPreset(TimePreset preset) {
    // 既に存在する場合は追加しない
    if (state.any((p) => p.label == preset.label)) {
      return;
    }

    // 最大5個まで
    if (state.length >= 5) {
      return;
    }

    state = [...state, preset];
    _saveToStorage();
  }

  /// プリセットを削除
  void removePreset(String label) {
    state = state.where((p) => p.label != label).toList();
    _saveToStorage();
  }

  /// デフォルトプリセットにリセット
  void resetToDefaults() {
    state = _defaultPresets;
    _saveToStorage();
  }

  /// 全削除
  void clearAll() {
    state = [];
    _saveToStorage();
  }
}

/// 時間設定プリセットプロバイダー
final timePresetProvider =
    StateNotifierProvider<TimePresetNotifier, List<TimePreset>>((ref) {
  return TimePresetNotifier();
});
