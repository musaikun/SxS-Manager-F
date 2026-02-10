import 'package:flutter/material.dart';

/// シフト管理機能で使用する定数
class ShiftConstants {
  ShiftConstants._();

  // ============================================================
  // 色定義
  // ============================================================

  /// 選択済み状態の色（緑）
  static const Color selectedColor = Colors.green;

  /// アクション可能状態の色（青）
  static const Color actionableColor = Colors.blue;

  /// 無効状態の色（灰色）
  static Color disabledColor = Colors.grey.shade400;

  /// 削除・クリアの色（赤）
  static const Color deleteColor = Colors.red;

  /// カスタムプリセットの色（紫）
  static const Color customPresetColor = Colors.purple;

  /// 警告・注意の色（オレンジ）
  static const Color warningColor = Colors.orange;

  /// 日曜日のテキスト色
  static const Color sundayColor = Colors.red;

  /// 土曜日のテキスト色
  static const Color saturdayColor = Colors.blue;

  /// 祝日のテキスト色
  static const Color holidayColor = Colors.pink;

  /// カレンダーセルの背景色
  static Color calendarCellBackground = Colors.grey[200]!;

  // ============================================================
  // サイズ定義
  // ============================================================

  /// カレンダーセルのサイズ
  static const double calendarCellSize = 40.0;

  /// カレンダーセルの角丸
  static const double calendarCellRadius = 8.0;

  /// ページインジケータードットのサイズ
  static const double pageIndicatorDotSize = 8.0;

  /// ページインジケータードットの間隔
  static const double pageIndicatorDotSpacing = 3.0;

  // ============================================================
  // 時間設定関連
  // ============================================================

  /// スライダーの最小値（0:00 = 0分）
  static const double sliderMinValue = 0.0;

  /// スライダーの最大値（23:45 = 1425分）
  static const double sliderMaxValue = 1425.0;

  /// スライダーの分割数（15分刻みで96分割）
  static const int sliderDivisions = 95;

  /// 最小勤務時間（分）
  static const int minimumWorkingMinutes = 60;

  /// 15分刻みの値
  static const int quarterHourMinutes = 15;

  // ============================================================
  // デフォルト時間プリセット
  // ============================================================

  static const List<Map<String, dynamic>> defaultTimePresets = [
    {'label': '9:00-18:00', 'startHour': 9, 'startMinute': 0, 'endHour': 18, 'endMinute': 0},
    {'label': '10:00-19:00', 'startHour': 10, 'startMinute': 0, 'endHour': 19, 'endMinute': 0},
    {'label': '13:00-22:00', 'startHour': 13, 'startMinute': 0, 'endHour': 22, 'endMinute': 0},
    {'label': '17:00-23:00', 'startHour': 17, 'startMinute': 0, 'endHour': 23, 'endMinute': 0},
  ];

  // ============================================================
  // メッセージ
  // ============================================================

  static const String messageNoDateSelected = '日付を選択してください';
  static const String messageNoTimeSet = '開始時刻と終了時刻を設定してください';
  static const String messageSaved = '保存しました';
  static const String messagePresetAdded = 'を追加しました';
  static const String messagePresetDeleted = 'を削除しました';
  static const String messageTimeSetForBatch = '件の時間を設定しました';

  // ============================================================
  // 曜日表示
  // ============================================================

  static const List<String> weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

  static List<Color> weekdayColors = [
    sundayColor,    // 日
    Colors.grey,    // 月
    Colors.grey,    // 火
    Colors.grey,    // 水
    Colors.grey,    // 木
    Colors.grey,    // 金
    saturdayColor,  // 土
  ];

  // ============================================================
  // その他
  // ============================================================

  /// 表示する月の数（現在月から何ヶ月先まで）
  static const int monthsToDisplay = 4;

  /// カスタムプリセット保存キー
  static const String customPresetsStorageKey = 'custom_time_presets';
}
