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

  /// 日付を追加（店舗指定）
  void addDate(DateTime date, String storeId) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final shiftDate = ShiftDate(date: normalizedDate, storeId: storeId);

    // 既に存在しない場合のみ追加（同じ日付+店舗IDの組み合わせ）
    if (!state.any((d) => d.uniqueKey == shiftDate.uniqueKey)) {
      final newList = [...state, shiftDate];
      newList.sort((a, b) => a.date.compareTo(b.date));
      state = newList;
      _saveToStorage();
    }
  }

  /// 複数の日付を追加（店舗指定）
  void addDates(List<DateTime> dates, String storeId) {
    final newDates = <ShiftDate>[];
    for (final date in dates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final shiftDate = ShiftDate(date: normalizedDate, storeId: storeId);

      // 既に存在しない場合のみ追加
      if (!state.any((d) => d.uniqueKey == shiftDate.uniqueKey)) {
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

  /// 日付を削除（uniqueKeyで指定）
  void removeDate(String uniqueKey) {
    state = state.where((d) => d.uniqueKey != uniqueKey).toList();
    _saveToStorage();
  }

  /// 特定の日付のすべての店舗を削除
  void removeDateAllStores(String dateString) {
    state = state.where((d) => d.dateString != dateString).toList();
    _saveToStorage();
  }

  /// 特定の店舗のすべてのシフトを削除
  void removeStore(String storeId) {
    state = state.where((d) => d.storeId != storeId).toList();
    _saveToStorage();
  }

  /// 全削除
  void clearAll() {
    state = [];
    _saveToStorage();
  }

  /// 特定の日付の時間を更新（uniqueKeyで指定）
  void updateTime(String uniqueKey, String? startTime, String? endTime) {
    state = state.map((d) {
      if (d.uniqueKey == uniqueKey) {
        return d.copyWith(startTime: startTime, endTime: endTime);
      }
      return d;
    }).toList();
    _saveToStorage();
  }

  /// 複数の日付に同じ時間を一括設定（uniqueKeyリストで指定）
  void updateMultipleTimes(
    List<String> uniqueKeys,
    String? startTime,
    String? endTime,
  ) {
    state = state.map((d) {
      if (uniqueKeys.contains(d.uniqueKey)) {
        return d.copyWith(startTime: startTime, endTime: endTime);
      }
      return d;
    }).toList();
    _saveToStorage();
  }

  /// メモを更新（uniqueKeyで指定）
  void updateMemo(String uniqueKey, String? memo) {
    state = state.map((d) {
      if (d.uniqueKey == uniqueKey) {
        return d.copyWith(memo: memo);
      }
      return d;
    }).toList();
    _saveToStorage();
  }

  /// 日付が選択されているか確認（特定の店舗で）
  bool isDateSelected(DateTime date, String storeId) {
    final dateString = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return state.any((d) => d.dateString == dateString && d.storeId == storeId);
  }

  /// 特定の日付のシフト数を取得
  int getShiftCountForDate(DateTime date) {
    final dateString = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return state.where((d) => d.dateString == dateString).length;
  }

  /// 特定の日付のシフトを取得
  List<ShiftDate> getShiftsForDate(DateTime date) {
    final dateString = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return state.where((d) => d.dateString == dateString).toList();
  }

  /// 特定の店舗のシフトを取得
  List<ShiftDate> getShiftsForStore(String storeId) {
    return state.where((d) => d.storeId == storeId).toList();
  }
}

/// シフト日付プロバイダー
final shiftDateProvider =
    StateNotifierProvider<ShiftDateNotifier, List<ShiftDate>>((ref) {
  return ShiftDateNotifier();
});
