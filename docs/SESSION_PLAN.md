# セッション分割実行プラン

## 前提条件

### Git ブランチ戦略
```
main
  └── develop (統合ブランチ)
      ├── feature/batch-time-setting
      ├── feature/default-time
      ├── feature/wage-calculation
      └── feature/confirmation-screen
```

### セッション開始時の必須チェック
1. `git checkout develop`
2. `git pull origin develop`
3. `git checkout -b feature/xxx`
4. ドキュメントを読む（ARCHITECTURE.md, FEATURES.md）

---

## 🎯 プラン A：実用重視（推奨）

**目的:** 今すぐ使える機能を完成させる

### セッション1：一括時間設定
- **Branch:** `feature/batch-time-setting`
- **期間:** 1セッション（2-3時間想定）
- **変更ファイル:**
  - `lib/features/shift/presentation/shift_list_screen.dart` (改修)
  - `lib/features/shift/presentation/batch_time_dialog.dart` (新規)

**実装内容:**
```dart
// shift_list_screen.dart に追加
// - チェックボックスで複数選択
// - 「一括時間設定」ボタン
// - ダイアログで時間入力 → 一括更新
```

**完了条件:**
- [ ] 複数のシフトを選択できる
- [ ] 一括で同じ時間を設定できる
- [ ] 設定後、リストに反映される
- [ ] ビルドエラーなし

**マージ:** develop へマージ後、セッション終了

---

### セッション2：デフォルト時間設定
- **Branch:** `feature/default-time`
- **期間:** 1セッション
- **変更ファイル:**
  - `lib/features/shift/domain/models/store.dart` (改修)
  - `lib/features/shift/providers/store_provider.dart` (改修)
  - `lib/features/shift/presentation/default_time_screen.dart` (新規)

**実装内容:**
```dart
// Store モデルに追加
class Store {
  ...
  final String? defaultStartTime;
  final String? defaultEndTime;
}

// 新規画面: デフォルト時間設定
// AppBarの「店舗管理」から遷移
```

**完了条件:**
- [ ] 店舗ごとにデフォルト時間を設定できる
- [ ] 時間設定画面で自動入力される
- [ ] SharedPreferences に保存される

**マージ:** develop へマージ後、セッション終了

---

### セッション3：確認・提出画面
- **Branch:** `feature/confirmation-screen`
- **期間:** 1セッション
- **変更ファイル:**
  - `lib/features/shift/presentation/confirmation_screen.dart` (新規)
  - `lib/features/shift/domain/models/shift_date.dart` (軽微な改修)

**実装内容:**
```dart
// ShiftListScreen から「確定」ボタンで遷移
// カレンダー形式で全体を表示
// 「提出」ボタンで確定
```

**完了条件:**
- [ ] 全体を俯瞰できる確認画面
- [ ] 提出機能（将来のサーバー連携を想定）

**マージ:** develop へマージ後、セッション終了

---

## 🎯 プラン B：段階的設計（上級者向け）

**目的:** 将来の拡張性を考慮した設計

### セッション1：データモデル設計
- **Branch:** `feature/wage-model-design`
- **期間:** 1セッション
- **変更ファイル:**
  - `lib/features/shift/domain/models/store.dart` (改修)
  - `lib/features/wage/domain/models/wage_setting.dart` (新規)
  - `docs/API_DESIGN.md` (新規 - インターフェース定義)

**実装内容:**
```dart
// Store に時給情報を追加
class Store {
  ...
  final double hourlyWage;
}

// WageSetting モデル作成
class WageSetting {
  final String storeId;
  final double baseWage;
  final double overtimeWage;
  final Map<DayOfWeek, double> dayOfWeekWage; // 曜日別時給
}
```

**完了条件:**
- [ ] モデル定義完了
- [ ] JSON シリアライズ対応
- [ ] インターフェース定義書作成

**マージ:** develop へマージ

---

### セッション2：計算ロジック実装
- **Branch:** `feature/wage-calculator`
- **期間:** 1セッション
- **依存:** セッション1完了後
- **変更ファイル:**
  - `lib/features/wage/domain/wage_calculator.dart` (新規)
  - `lib/features/wage/providers/wage_provider.dart` (新規)

**実装内容:**
```dart
// 勤務時間計算
// 時給計算
// 月次集計ロジック
```

**完了条件:**
- [ ] ユニットテスト通過
- [ ] 計算ロジック検証済み

**マージ:** develop へマージ

---

### セッション3：UI実装
- **Branch:** `feature/wage-summary-ui`
- **期間:** 1セッション
- **依存:** セッション2完了後
- **変更ファイル:**
  - `lib/features/wage/presentation/summary_screen.dart` (新規)
  - `lib/features/wage/presentation/wage_detail_screen.dart` (新規)

**実装内容:**
```dart
// 月次集計画面
// グラフ表示
// 店舗別集計
```

**完了条件:**
- [ ] 集計データが正しく表示される
- [ ] グラフが描画される

**マージ:** develop へマージ

---

## 🛠️ セッション実行テンプレート

各セッション開始時に以下をコピーして使用：

```markdown
## セッション情報
- **日付:** 2026-XX-XX
- **Branch:** feature/xxx
- **目的:** XXX機能の実装
- **依存:** なし / セッションXXX完了後

## 開始前チェック
- [ ] develop ブランチを最新化 (`git pull origin develop`)
- [ ] 新しいブランチ作成 (`git checkout -b feature/xxx`)
- [ ] ドキュメント確認 (ARCHITECTURE.md, FEATURES.md)

## 実装ファイル
- [ ] ファイルA (新規/改修)
- [ ] ファイルB (新規/改修)

## 完了条件
- [ ] 機能が動作する
- [ ] ビルドエラーなし
- [ ] 既存機能に影響なし

## 終了時チェック
- [ ] テスト実行 (`flutter test`)
- [ ] ビルド確認 (`flutter build apk --debug`)
- [ ] コミット (`git commit -m "feat: XXX"`)
- [ ] プッシュ (`git push -u origin feature/xxx`)
- [ ] develop にマージ
- [ ] セッションログ作成 (session_logs/session_XXX.md)

## トラブルシューティング
- エラーが出た場合: [エラー内容をメモ]
- 解決方法: [対処内容をメモ]
```

---

## 🚨 競合発生時の対処フロー

### ケース1：マージ競合
```bash
# develop にマージしようとしたら競合
git checkout feature/A
git merge develop

# 競合発生
# CONFLICT (content): Merge conflict in XXX.dart

# 対処
1. ファイルを開く
2. <<<<<<< HEAD と ======= の間があなたのコード
3. ======= と >>>>>>> develop の間が develop のコード
4. 手動で統合（Claude Code に依頼可能）
5. git add XXX.dart
6. git commit -m "Merge develop and resolve conflicts"
```

### ケース2：仕様の不一致
```
セッション1: Store に hourlyWage (double) を追加
セッション2: Store に hourlyWage (int) を追加（別セッション）

→ 設計ドキュメント (API_DESIGN.md) を参照して統一
```

---

## 📊 進捗管理

### 現在の状態
- ✅ Phase 1: コア機能（完成）
- 🚧 Phase 2: 時間管理機能（次）
- ⏳ Phase 3: 確認・提出機能
- ⏳ Phase 4: 時給・集計機能
- ⏳ Phase 5: 認証・管理機能

### 次に着手すべきセッション
**推奨:** プランA - セッション1（一括時間設定）

理由：
- 既存機能の改善（すぐに価値を提供）
- 1セッションで完結
- 競合リスクが中程度（管理可能）

---

## ❓ 判断基準

### いつ機能を分割すべきか？
- ファイルが完全に分離できる → 分割OK
- 1セッションが3時間以上かかる → 分割検討
- 依存関係が複雑 → 設計セッションを先に実施

### いつ統合すべきか？
- 小さな改善（1ファイルのみ） → 統合
- 密結合な機能 → 統合
- 1セッションで完結する → 統合

**迷ったら統合を選ぶ方が安全です。**

---

どのプランで進めますか？
- プランA（実用重視）
- プランB（設計重視）
- 別の提案が欲しい
