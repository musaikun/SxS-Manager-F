import 'package:flutter/material.dart';

/// 時間計算のユーティリティクラス
class TimeUtils {
  TimeUtils._();

  /// 1日の分数（24時間）
  static const int minutesPerDay = 1440;

  /// TimeOfDayを分単位に変換
  static int timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// 分単位をTimeOfDayに変換
  static TimeOfDay minutesToTime(int minutes) {
    return TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
  }

  /// TimeOfDayを文字列に変換（HH:MM形式）
  static String timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 文字列をTimeOfDayに変換（HH:MM形式）
  static TimeOfDay? stringToTime(String? timeString) {
    if (timeString == null) return null;
    try {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  /// 分を15分刻みに丸める
  static int roundToQuarterHour(int minutes) {
    if (minutes < 8) return 0;
    if (minutes < 23) return 15;
    if (minutes < 38) return 30;
    if (minutes < 53) return 45;
    return 0; // 53以上は次の時間の0分
  }

  /// 勤務時間を計算（時間単位、日をまたぐ場合も対応）
  static double? calculateWorkHours(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return null;

    try {
      final start = stringToTime(startTime);
      final end = stringToTime(endTime);
      if (start == null || end == null) return null;

      final startMinutes = timeToMinutes(start);
      var endMinutes = timeToMinutes(end);

      // 日をまたぐ場合（終了時刻が開始時刻より前）
      if (endMinutes <= startMinutes) {
        endMinutes += minutesPerDay;
      }

      return (endMinutes - startMinutes) / 60.0;
    } catch (e) {
      return null;
    }
  }

  /// 勤務時間を文字列で取得（例：9時間30分）
  static String formatWorkingHours(TimeOfDay? startTime, TimeOfDay? endTime) {
    if (startTime == null || endTime == null) {
      return '--';
    }

    final startMinutes = timeToMinutes(startTime);
    var endMinutes = timeToMinutes(endTime);

    // 終了時刻が開始時刻より前の場合は翌日とみなす
    if (endMinutes <= startMinutes) {
      endMinutes += minutesPerDay;
    }

    final diff = endMinutes - startMinutes;
    final hours = diff ~/ 60;
    final minutes = diff % 60;

    return '$hours時間${minutes > 0 ? "$minutes分" : ""}';
  }

  /// 日をまたぐかどうか判定
  static bool crossesMidnight(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = timeToMinutes(startTime);
    final endMinutes = timeToMinutes(endTime);
    return endMinutes <= startMinutes;
  }

  /// 労働基準法に基づく休憩時間を計算（分単位）
  /// - 6時間未満：0分
  /// - 6時間以上8時間未満：45分
  /// - 8時間以上：60分
  static int calculateBreakTime(double workHours) {
    if (workHours < 6.0) {
      return 0;
    } else if (workHours < 8.0) {
      return 45;
    } else {
      return 60;
    }
  }

  /// 実労働時間を計算（休憩時間を差し引いた時間）
  static double? calculateActualWorkHours(String? startTime, String? endTime) {
    final totalHours = calculateWorkHours(startTime, endTime);
    if (totalHours == null) return null;

    final breakMinutes = calculateBreakTime(totalHours);
    return totalHours - (breakMinutes / 60.0);
  }
}
