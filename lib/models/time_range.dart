import 'package:flutter/material.dart';

/// 時間範囲を表すモデルクラス
/// シフトの開始時間と終了時間を管理する
class TimeRange {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const TimeRange({
    required this.startTime,
    required this.endTime,
  });

  /// デフォルトの勤務時間（9:00-17:00）
  factory TimeRange.defaultWorkHours() {
    return const TimeRange(
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 17, minute: 0),
    );
  }

  /// 時間をコピーして新しいインスタンスを作成
  TimeRange copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return TimeRange(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// 勤務時間を分単位で計算（日をまたぐ場合も考慮）
  int get durationInMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes >= startMinutes) {
      return endMinutes - startMinutes;
    } else {
      // 日をまたぐ場合（例：22:00 - 06:00）
      return (24 * 60 - startMinutes) + endMinutes;
    }
  }

  /// 時間を "HH:MM" 形式の文字列に変換
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 時間範囲を "HH:MM - HH:MM" 形式で表示
  String get formattedRange {
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  @override
  String toString() => 'TimeRange($formattedRange)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeRange &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}
