# S×S Manager アーキテクチャ設計

## プロジェクト概要
シフト管理アプリケーション - 複数店舗対応、時間設定、集計機能を持つFlutterアプリ

## 技術スタック
- Flutter 3.16+
- Dart 3.2+
- Riverpod (状態管理)
- SharedPreferences (ローカルストレージ)
- table_calendar 3.0.9

## ディレクトリ構造
```
lib/
├── features/
│   ├── shift/
│   │   ├── domain/
│   │   │   └── models/           # データモデル
│   │   │       ├── shift_date.dart
│   │   │       └── store.dart
│   │   ├── providers/            # 状態管理
│   │   │   ├── shift_date_provider.dart
│   │   │   └── store_provider.dart
│   │   └── presentation/         # UI
│   │       ├── date_selection_screen.dart
│   │       ├── shift_list_screen.dart
│   │       └── time_setting_screen.dart
│   ├── wage/                     # 【未実装】時給・集計機能
│   ├── auth/                     # 【未実装】認証機能
│   └── admin/                    # 【未実装】管理機能
└── main.dart
```

## データモデル設計

### ShiftDate
```dart
class ShiftDate {
  final DateTime date;
  final String storeId;
  final String? startTime;
  final String? endTime;
  final String? memo;

  String get uniqueKey => '${dateString}_$storeId';
}
```

### Store
```dart
class Store {
  final String id;
  final String name;
  final Color color;
}
```

## Provider設計

### ShiftDateProvider
- 責務: シフト日付の管理
- メソッド:
  - `addDates(List<DateTime>, String storeId)`
  - `removeDate(String uniqueKey)`
  - `updateTime(String uniqueKey, String? start, String? end)`
  - `getShiftsForDate(DateTime date)`
  - `getShiftCountForDate(DateTime date)`

### StoreProvider
- 責務: 店舗マスタの管理
- メソッド:
  - `addStore(String name)`
  - `removeStore(String id)`
  - `renameStore(String id, String name)`

## 画面遷移フロー
```
DateSelectionScreen (日付選択)
  ↓ 「次へ」ボタン
ShiftListScreen (選択済み一覧)
  ↓ 日付タップ
TimeSettingScreen (時間設定)
  ↓ 保存
ShiftListScreen に戻る
  ↓ 「確定」ボタン（未実装）
ConfirmationScreen (確認画面)
```

## 制約事項
- 店舗数: 最大4店舗（UI制約）
- 日付範囲: 2020年〜2030年
- 過去日付: 選択不可
- カラーパレット: 赤・青・黄・緑（4色固定）

## セッション分割方針

### 完成済み機能（変更時は慎重に）
- ✅ 日付選択画面
- ✅ 店舗管理
- ✅ 基本的なシフト一覧

### 未実装機能（新規セッションで実装可能）
- ⏳ 時間設定の一括入力
- ⏳ デフォルト時間設定
- ⏳ 時給計算機能
- ⏳ 集計・レポート画面
- ⏳ 認証機能
- ⏳ 管理者機能

## ファイル変更ガイドライン

### 【注意】既存ファイル（競合リスク高）
- `date_selection_screen.dart` - 複数セッションでの変更は避ける
- `shift_date_provider.dart` - インターフェース変更は全体に影響
- `store_provider.dart` - 店舗モデル変更は全体に影響

### 【推奨】新規ファイル（競合リスク低）
- 時給機能 → 新規ファイル群
- 認証機能 → 新規ファイル群
- 集計機能 → 新規ファイル群

## 更新履歴
- 2026-01-23: 初版作成（日付選択機能完成時点）
