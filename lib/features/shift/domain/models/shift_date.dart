/// シフト日付モデル
class ShiftDate {
  final DateTime date;
  final String? startTime; // 例: "10:00"
  final String? endTime; // 例: "18:00"
  final String? memo;

  ShiftDate({
    required this.date,
    this.startTime,
    this.endTime,
    this.memo,
  });

  /// 日付のみの文字列を取得（ISO 8601形式）
  String get dateString =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 時間が設定されているか
  bool get hasTime => startTime != null && endTime != null;

  /// コピーメソッド
  ShiftDate copyWith({
    DateTime? date,
    String? startTime,
    String? endTime,
    String? memo,
    bool clearStartTime = false,
    bool clearEndTime = false,
    bool clearMemo = false,
  }) {
    return ShiftDate(
      date: date ?? this.date,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      memo: clearMemo ? null : (memo ?? this.memo),
    );
  }

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'date': dateString,
      'startTime': startTime,
      'endTime': endTime,
      'memo': memo,
    };
  }

  factory ShiftDate.fromJson(Map<String, dynamic> json) {
    return ShiftDate(
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      memo: json['memo'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftDate &&
          runtimeType == other.runtimeType &&
          dateString == other.dateString;

  @override
  int get hashCode => dateString.hashCode;
}
