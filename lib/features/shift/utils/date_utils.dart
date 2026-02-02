import 'package:flutter/material.dart';

/// 日付関連のユーティリティクラス
class ShiftDateUtils {
  ShiftDateUtils._();

  /// 日付を正規化（時刻情報を削除してUTC日付のみにする）
  static DateTime normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// 月の第何週かを取得（1始まり）
  static int getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final daysSinceFirstDay = date.difference(firstDayOfMonth).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }

  /// 平日かどうか判定
  static bool isWeekday(DateTime date) {
    return date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;
  }

  /// 土日かどうか判定
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// 土日祝かどうか判定
  static bool isWeekendOrHoliday(DateTime date) {
    return isWeekend(date) || JapaneseHolidays.isHoliday(date);
  }

  /// 過去日かどうか判定
  static bool isPastDate(DateTime date) {
    final today = normalizeDate(DateTime.now());
    return normalizeDate(date).isBefore(today);
  }
}

/// 日本の祝日管理クラス
class JapaneseHolidays {
  JapaneseHolidays._();

  /// 2025-2026年の祝日リスト
  static final Map<DateTime, String> _holidays = {
    // 2025年
    DateTime.utc(2025, 1, 1): '元日',
    DateTime.utc(2025, 1, 13): '成人の日',
    DateTime.utc(2025, 2, 11): '建国記念の日',
    DateTime.utc(2025, 2, 23): '天皇誕生日',
    DateTime.utc(2025, 2, 24): '振替休日',
    DateTime.utc(2025, 3, 20): '春分の日',
    DateTime.utc(2025, 4, 29): '昭和の日',
    DateTime.utc(2025, 5, 3): '憲法記念日',
    DateTime.utc(2025, 5, 4): 'みどりの日',
    DateTime.utc(2025, 5, 5): 'こどもの日',
    DateTime.utc(2025, 5, 6): '振替休日',
    DateTime.utc(2025, 7, 21): '海の日',
    DateTime.utc(2025, 8, 11): '山の日',
    DateTime.utc(2025, 9, 15): '敬老の日',
    DateTime.utc(2025, 9, 23): '秋分の日',
    DateTime.utc(2025, 10, 13): 'スポーツの日',
    DateTime.utc(2025, 11, 3): '文化の日',
    DateTime.utc(2025, 11, 23): '勤労感謝の日',
    DateTime.utc(2025, 11, 24): '振替休日',
    // 2026年
    DateTime.utc(2026, 1, 1): '元日',
    DateTime.utc(2026, 1, 12): '成人の日',
    DateTime.utc(2026, 2, 11): '建国記念の日',
    DateTime.utc(2026, 2, 23): '天皇誕生日',
    DateTime.utc(2026, 3, 20): '春分の日',
    DateTime.utc(2026, 4, 29): '昭和の日',
    DateTime.utc(2026, 5, 3): '憲法記念日',
    DateTime.utc(2026, 5, 4): 'みどりの日',
    DateTime.utc(2026, 5, 5): 'こどもの日',
    DateTime.utc(2026, 5, 6): '振替休日',
    DateTime.utc(2026, 7, 20): '海の日',
    DateTime.utc(2026, 8, 11): '山の日',
    DateTime.utc(2026, 9, 21): '敬老の日',
    DateTime.utc(2026, 9, 22): '国民の休日',
    DateTime.utc(2026, 9, 23): '秋分の日',
    DateTime.utc(2026, 10, 12): 'スポーツの日',
    DateTime.utc(2026, 11, 3): '文化の日',
    DateTime.utc(2026, 11, 23): '勤労感謝の日',
  };

  /// 指定日が祝日かどうか判定
  static bool isHoliday(DateTime date) {
    final normalized = ShiftDateUtils.normalizeDate(date);
    return _holidays.containsKey(normalized);
  }

  /// 祝日名を取得（祝日でない場合はnull）
  static String? getHolidayName(DateTime date) {
    final normalized = ShiftDateUtils.normalizeDate(date);
    return _holidays[normalized];
  }

  /// 全祝日リストを取得
  static Map<DateTime, String> get holidays => Map.unmodifiable(_holidays);
}
