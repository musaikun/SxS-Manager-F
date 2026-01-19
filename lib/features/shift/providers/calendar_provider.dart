import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/calendar_state.dart';
import '../domain/models/job.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// カレンダー状態管理Notifier
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(_initialState()) {
    _loadFromStorage();
  }

  static CalendarState _initialState() {
    final now = DateTime.now();
    return CalendarState(
      currentYear: now.year,
      currentMonth: now.month,
    );
  }

  // ==================== データ永続化 ====================

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('calendar_state');

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = CalendarState.fromJson(
          json,
          state.currentYear,
          state.currentMonth,
        );
      }
    } catch (e) {
      print('Failed to load calendar state: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('calendar_state', jsonEncode(state.toJson()));
    } catch (e) {
      print('Failed to save calendar state: $e');
    }
  }

  // ==================== 日付操作 ====================

  /// 日付を正規化（ISO 8601形式）
  String _formatDateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// 日付の選択/解除
  void toggleDate(DateTime date) {
    final dateString = _formatDateString(date);

    if (state.currentJobId == null) {
      // 本店モード
      final newSelected = Set<String>.from(state.selectedDates);
      if (newSelected.contains(dateString)) {
        newSelected.remove(dateString);
      } else {
        newSelected.add(dateString);
      }
      state = state.copyWith(selectedDates: newSelected);
    } else {
      // ジョブモード - ディープコピー
      final newDateJobMap = state.dateJobMap.map(
        (key, value) => MapEntry(key, Set<int>.from(value)),
      );
      newDateJobMap.putIfAbsent(dateString, () => <int>{});

      if (newDateJobMap[dateString]!.contains(state.currentJobId)) {
        newDateJobMap[dateString]!.remove(state.currentJobId);
        if (newDateJobMap[dateString]!.isEmpty) {
          newDateJobMap.remove(dateString);
        }
      } else {
        newDateJobMap[dateString]!.add(state.currentJobId!);
      }
      state = state.copyWith(dateJobMap: newDateJobMap);
    }

    _saveToStorage();
  }

  /// 日付が選択されているか確認
  bool isDateSelected(String dateString) {
    if (state.currentJobId == null) {
      return state.selectedDates.contains(dateString);
    } else {
      return state.dateJobMap[dateString]?.contains(state.currentJobId) ??
          false;
    }
  }

  // ==================== 一括選択 ====================

  /// 全日選択
  void selectAll(List<DateTime> dates) {
    if (state.currentJobId == null) {
      final newSelected = Set<String>.from(state.selectedDates);
      for (final date in dates) {
        newSelected.add(_formatDateString(date));
      }
      state = state.copyWith(selectedDates: newSelected);
    } else {
      final newDateJobMap = state.dateJobMap.map(
        (key, value) => MapEntry(key, Set<int>.from(value)),
      );
      for (final date in dates) {
        final dateString = _formatDateString(date);
        newDateJobMap.putIfAbsent(dateString, () => {});
        newDateJobMap[dateString]!.add(state.currentJobId!);
      }
      state = state.copyWith(dateJobMap: newDateJobMap);
    }

    _saveToStorage();
  }

  /// 平日のみ選択
  void selectWeekdays(List<DateTime> weekdayDates) {
    selectAll(weekdayDates);
  }

  /// 曜日別選択
  void toggleWeekday(int weekday, List<DateTime> weekdayDates) {
    // すべて選択済みかチェック
    final allSelected = weekdayDates.every((date) {
      return isDateSelected(_formatDateString(date));
    });

    if (allSelected) {
      // 解除
      if (state.currentJobId == null) {
        final newSelected = Set<String>.from(state.selectedDates);
        for (final date in weekdayDates) {
          newSelected.remove(_formatDateString(date));
        }
        state = state.copyWith(selectedDates: newSelected);
      } else {
        final newDateJobMap = state.dateJobMap.map(
          (key, value) => MapEntry(key, Set<int>.from(value)),
        );
        for (final date in weekdayDates) {
          final dateString = _formatDateString(date);
          newDateJobMap[dateString]?.remove(state.currentJobId);
          if (newDateJobMap[dateString]?.isEmpty ?? false) {
            newDateJobMap.remove(dateString);
          }
        }
        state = state.copyWith(dateJobMap: newDateJobMap);
      }
    } else {
      // 選択
      selectAll(weekdayDates);
    }

    _saveToStorage();
  }

  /// 土日祝日選択
  void selectWeekendsAndHolidays(List<DateTime> dates) {
    selectAll(dates);
  }

  /// 全クリア
  void clearAll() {
    if (state.currentJobId == null) {
      state = state.copyWith(selectedDates: {});
    } else {
      final newDateJobMap = state.dateJobMap.map(
        (key, value) => MapEntry(key, Set<int>.from(value)),
      );
      for (final entry in newDateJobMap.entries.toList()) {
        entry.value.remove(state.currentJobId);
        if (entry.value.isEmpty) {
          newDateJobMap.remove(entry.key);
        }
      }
      state = state.copyWith(dateJobMap: newDateJobMap);
    }

    _saveToStorage();
  }

  // ==================== ジョブ管理 ====================

  /// ジョブ追加
  Job? addJob(String name) {
    if (state.jobs.length >= 4) return null;

    final id = state.jobs.length + 1;
    final job = Job(
      id: id,
      name: name.length > 14 ? name.substring(0, 14) : name,
      color: jobColors[id]!,
    );

    final newJobs = List<Job>.from(state.jobs)..add(job);
    state = state.copyWith(jobs: newJobs);
    _saveToStorage();

    return job;
  }

  /// ジョブ削除
  void removeJob(int jobId) {
    final newJobs = state.jobs.where((j) => j.id != jobId).toList();
    final newDateJobMap = state.dateJobMap.map(
      (key, value) => MapEntry(key, Set<int>.from(value)),
    );

    // dateJobMapから該当ジョブを削除
    for (final entry in newDateJobMap.entries.toList()) {
      entry.value.remove(jobId);
      if (entry.value.isEmpty) {
        newDateJobMap.remove(entry.key);
      }
    }

    state = state.copyWith(
      jobs: newJobs,
      dateJobMap: newDateJobMap,
      clearCurrentJobId: state.currentJobId == jobId,
    );
    _saveToStorage();
  }

  /// ジョブ名変更
  void renameJob(int jobId, String newName) {
    final newJobs = state.jobs.map((j) {
      if (j.id == jobId) {
        return j.copyWith(
          name: newName.length > 14 ? newName.substring(0, 14) : newName,
        );
      }
      return j;
    }).toList();

    state = state.copyWith(jobs: newJobs);
    _saveToStorage();
  }

  /// ジョブ切り替え
  void switchJob(int? jobId) {
    if (jobId == null) {
      state = state.copyWith(clearCurrentJobId: true);
    } else {
      state = state.copyWith(currentJobId: jobId);
    }
  }

  // ==================== 月の切り替え ====================

  void changeMonth(int delta) {
    int newMonth = state.currentMonth + delta;
    int newYear = state.currentYear;

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    state = state.copyWith(
      currentYear: newYear,
      currentMonth: newMonth,
    );
  }

  void goToThisMonth() {
    final now = DateTime.now();
    state = state.copyWith(
      currentYear: now.year,
      currentMonth: now.month,
    );
  }

  void goToNextMonth() {
    changeMonth(1);
  }

  // ==================== 前月データコピー ====================

  void savePreviousMonthData() {
    if (state.currentJobId == null) {
      state = state.copyWith(
        previousMonthData: state.selectedDates.toList(),
      );
    } else {
      final jobDates = state.dateJobMap.entries
          .where((e) => e.value.contains(state.currentJobId))
          .map((e) => e.key)
          .toList();
      state = state.copyWith(previousMonthData: jobDates);
    }

    _saveToStorage();
  }

  void copyPreviousMonth() {
    if (state.previousMonthData == null || state.previousMonthData!.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final currentMonthDays =
        DateTime(state.currentYear, state.currentMonth + 1, 0).day;

    if (state.currentJobId == null) {
      final newSelected = Set<String>.from(state.selectedDates);

      for (final dateString in state.previousMonthData!) {
        final prevDate = DateTime.parse(dateString);
        final day = prevDate.day;

        if (day <= currentMonthDays) {
          final newDate = DateTime(state.currentYear, state.currentMonth, day);
          if (!newDate.isBefore(now) ||
              _isSameDay(newDate, now)) {
            newSelected.add(_formatDateString(newDate));
          }
        }
      }

      state = state.copyWith(selectedDates: newSelected);
    } else {
      final newDateJobMap = state.dateJobMap.map(
        (key, value) => MapEntry(key, Set<int>.from(value)),
      );

      for (final dateString in state.previousMonthData!) {
        final prevDate = DateTime.parse(dateString);
        final day = prevDate.day;

        if (day <= currentMonthDays) {
          final newDate = DateTime(state.currentYear, state.currentMonth, day);
          if (!newDate.isBefore(now) ||
              _isSameDay(newDate, now)) {
            final newDateString = _formatDateString(newDate);
            newDateJobMap.putIfAbsent(newDateString, () => {});
            newDateJobMap[newDateString]!.add(state.currentJobId!);
          }
        }
      }

      state = state.copyWith(dateJobMap: newDateJobMap);
    }

    _saveToStorage();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// カレンダープロバイダー
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});
