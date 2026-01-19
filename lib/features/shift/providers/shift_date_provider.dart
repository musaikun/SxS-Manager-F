import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/shift_date.dart';

/// シフト日付の状態管理
class ShiftDateNotifier extends StateNotifier<List<ShiftDate>> {
  ShiftDateNotifier() : super([]) {
    _loadFromStorage();
  }

  static const String _storageKey = 'shift_dates';

  // ==================== データ永続化 ====================

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final List<ShiftDate> dates = jsonList
            .map((json) => ShiftDate.fromJson(json as Map<String, dynamic>))
            .toList();

        // 日付順にソート
        dates.sort((a, b) => a.date.compareTo(b.date));
        state = dates;
      }
    } catch (e) {
      print('Failed to load shift dates: $e');
      // エラー時はデータをクリア
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((date) => date.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Failed to save shift dates: $e');
    }
  }

  // ==================== 日付操作 ====================

  /// 日付を追加
  void addDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final shiftDate = ShiftDate(date: normalizedDate);

    // 既に存在しない場合のみ追加
    if (!state.any((d) => d.dateString == shiftDate.dateString)) {
      final newList = [...state, shiftDate];
      newList.sort((a, b) => a.date.compareTo(b.date));
      state = newList;
      _saveToStorage();
    }
  }

  /// 複数の日付を追加
  void addDates(List<DateTime> dates) {
    final newDates = <ShiftDate>[];
    for (final date in dates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final shiftDate = ShiftDate(date: normalizedDate);

      // 既に存在しない場合のみ追加
      if (!state.any((d) => d.dateString == shiftDate.dateString)) {
        newDates.add(shiftDate);
      }
    }

    if (newDates.isNotEmpty) {
      final newList = [...state, ...newDates];
      newList.sort((a, b) => a.date.compareTo(b.date));
      state = newList;
      _saveToStorage();
    }
  }

  /// 日付を削除
  void removeDate(String dateString) {
    state = state.where((d) => d.dateString != dateString).toList();
    _saveToStorage();
  }

  /// 全削除
  void clearAll() {
    state = [];
    _saveToStorage();
  }

  /// 特定の日付の時間を更新
  void updateTime(String dateString, String? startTime, String? endTime) {
    state = state.map((d) {
      if (d.dateString == dateString) {
        return d.copyWith(startTime: startTime, endTime: endTime);
      }
      return d;
    }).toList();
    _saveToStorage();
  }

  /// 複数の日付に同じ時間を一括設定
  void updateMultipleTimes(
    List<String> dateStrings,
    String? startTime,
    String? endTime,
  ) {
    state = state.map((d) {
      if (dateStrings.contains(d.dateString)) {
        return d.copyWith(startTime: startTime, endTime: endTime);
      }
      return d;
    }).toList();
    _saveToStorage();
  }

  /// メモを更新
  void updateMemo(String dateString, String? memo) {
    state = state.map((d) {
      if (d.dateString == dateString) {
        return d.copyWith(memo: memo);
      }
      return d;
    }).toList();
    _saveToStorage();
  }

  /// 日付が選択されているか確認
  bool isDateSelected(DateTime date) {
    final dateString = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return state.any((d) => d.dateString == dateString);
  }

  /// 選択されている日付の文字列リストを取得
  List<String> getSelectedDateStrings() {
    return state.map((d) => d.dateString).toList();
  }
}

/// シフト日付プロバイダー
final shiftDateProvider =
    StateNotifierProvider<ShiftDateNotifier, List<ShiftDate>>((ref) {
  return ShiftDateNotifier();
});
