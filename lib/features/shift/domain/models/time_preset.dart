/// 時間設定のクイックプリセット
class TimePreset {
  final String label; // 表示名（例: "9:00-18:00"）
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isNextDay; // 翌日かどうか

  TimePreset({
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isNextDay = false,
  });

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'isNextDay': isNextDay,
    };
  }

  factory TimePreset.fromJson(Map<String, dynamic> json) {
    return TimePreset(
      label: json['label'] as String,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      isNextDay: json['isNextDay'] as bool? ?? false,
    );
  }

  /// 開始時刻を分単位で取得
  int get startMinutes => startHour * 60 + startMinute;

  /// 終了時刻を分単位で取得（翌日の場合は+1440）
  int get endMinutes => endHour * 60 + endMinute + (isNextDay ? 1440 : 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimePreset &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          endHour == other.endHour &&
          endMinute == other.endMinute &&
          isNextDay == other.isNextDay;

  @override
  int get hashCode => Object.hash(
        label,
        startHour,
        startMinute,
        endHour,
        endMinute,
        isNextDay,
      );
}
